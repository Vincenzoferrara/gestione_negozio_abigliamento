<?php
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

require_once __DIR__ . '/dashboard-functions.php';

if ( ! class_exists( 'myCRED_Dashboard_API' ) ) :

    class myCRED_Dashboard_API {

        protected static $instance = null;

        protected $namespace = 'mycred-dashboard/v1';

        public static function instance() {
            if ( null === self::$instance ) {
                self::$instance = new self();
            }
            return self::$instance;
        }

        private function __construct() {
            add_action( 'rest_api_init', array( $this, 'register_routes' ) );
        }

        public function register_routes() {
            register_rest_route( $this->namespace, '/dashboard-settings', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_dashboard_settings' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
            ));

            register_rest_route( $this->namespace, '/dashboard-settings', array(
                'methods'  => WP_REST_Server::CREATABLE,
                'callback' => array( $this, 'save_dashboard_settings' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'settings' => array(
                        'description' => __( 'Dashboard settings data.', 'mycred' ),
                        'type'        => 'object',
                        'required'    => true,
                    ),
                ),
            ));

            register_rest_route( $this->namespace, '/search-users', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'search_users' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'search'   => array(
                        'description' => __( 'Search query for users (login, name, or email).', 'mycred' ),
                        'type'        => 'string',
                        'required'    => true,
                        'sanitize_callback' => 'sanitize_text_field',
                    ),
                    'per_page' => array(
                        'description' => __( 'Number of users to return.', 'mycred' ),
                        'type'        => 'integer',
                        'default'     => 10,
                        'sanitize_callback' => 'absint',
                    ),
                ),
            ));

            register_rest_route( $this->namespace, '/users/(?P<id>\d+)', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_user' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'id' => array(
                        'description' => __( 'User ID.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => true,
                        'sanitize_callback' => 'absint',
                    ),
                ),
            ));

            register_rest_route( $this->namespace, '/users/(?P<id>\d+)/insights', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_user_insights' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'id' => array(
                        'description' => __( 'User ID.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => true,
                        'sanitize_callback' => 'absint',
                    ),
                    'point_type' => array(
                        'description' => __( 'Point type to evaluate.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                        'sanitize_callback' => 'sanitize_key',
                    ),
                    'range' => array(
                        'description' => __( 'Optional time range (today, this_week, this_month, custom, all).', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                    ),
                    'start' => array(
                        'description' => __( 'Custom range start date (Y-m-d).', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                    ),
                    'end' => array(
                        'description' => __( 'Custom range end date (Y-m-d).', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                    ),
                ),
            ));

            // Single endpoint for initial dashboard load and point type changes
            register_rest_route( $this->namespace, '/dashboard', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'dashboard_overview' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'point_type' => array(
                        'description' => __( 'Point type to load data for. If omitted, uses default from settings.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                        'sanitize_callback' => 'sanitize_key',
                    ),
                ),
            ));

            register_rest_route( $this->namespace, '/points/award', array(
                'methods'  => WP_REST_Server::CREATABLE,
                'callback' => array( $this, 'award_points' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'point_type' => array(
                        'description' => __( 'Point type to adjust.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                        'sanitize_callback' => 'sanitize_key',
                    ),
                    'user_ids' => array(
                        'description' => __( 'Array of user IDs.', 'mycred' ),
                        'type'        => 'array',
                        'items'       => array(
                            'type' => 'integer',
                        ),
                        'required'    => false,
                        'validate_callback' => function( $value ) {
                            if ( is_array( $value ) && ! empty( $value ) ) {
                                return true;
                            }
                            if ( is_scalar( $value ) ) {
                                return true;
                            }
                            return empty( $value );
                        },
                    ),
                    'amount' => array(
                        'description' => __( 'Positive amount of points.', 'mycred' ),
                        'type'        => 'number',
                        'required'    => true,
                    ),
                    'apply_to' => array(
                        'description' => __( 'Apply the adjustment to all users.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                        'enum'        => array( 'all' ),
                    ),
                    'message' => array(
                        'description' => __( 'Optional log entry message.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                    ),
                ),
            ));

            register_rest_route( $this->namespace, '/points/deduct', array(
                'methods'  => WP_REST_Server::CREATABLE,
                'callback' => array( $this, 'deduct_points' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'point_type' => array(
                        'description' => __( 'Point type to adjust.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                        'sanitize_callback' => 'sanitize_key',
                    ),
                    'user_ids' => array(
                        'description' => __( 'Array of user IDs.', 'mycred' ),
                        'type'        => 'array',
                        'items'       => array(
                            'type' => 'integer',
                        ),
                        'required'    => false,
                        'validate_callback' => function( $value ) {
                            if ( is_array( $value ) && ! empty( $value ) ) {
                                return true;
                            }
                            if ( is_scalar( $value ) ) {
                                return true;
                            }
                            return empty( $value );
                        },
                    ),
                    'amount' => array(
                        'description' => __( 'Positive amount of points.', 'mycred' ),
                        'type'        => 'number',
                        'required'    => true,
                    ),
                    'apply_to' => array(
                        'description' => __( 'Apply the adjustment to all users.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                        'enum'        => array( 'all' ),
                    ),
                    'message' => array(
                        'description' => __( 'Optional log entry message.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                    ),
                ),
            ));

            register_rest_route( $this->namespace, '/points/reset', array(
                'methods'  => WP_REST_Server::CREATABLE,
                'callback' => array( $this, 'reset_points' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'user_id' => array(
                        'description' => __( 'User ID to reset points for.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => true,
                        'sanitize_callback' => 'absint',
                    ),
                    'point_type' => array(
                        'description' => __( 'Point type to reset. If omitted, resets all point types.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                        'sanitize_callback' => 'sanitize_key',
                    ),
                ),
            ));

            register_rest_route( $this->namespace, '/users/(?P<id>\d+)/history', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_user_history' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'id' => array(
                        'description' => __( 'User ID.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => true,
                        'sanitize_callback' => 'absint',
                    ),
                    'point_type' => array(
                        'description' => __( 'Point type to get history for.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                        'sanitize_callback' => 'sanitize_key',
                    ),
                    'filter' => array(
                        'description' => __( 'Filter option (most_recent, oldest_first, highest_first, lowest_first).', 'mycred' ),
                        'type'        => 'string',
                        'required'    => false,
                        'default'     => 'most_recent',
                    ),
                    'page' => array(
                        'description' => __( 'Page number.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => false,
                        'default'     => 1,
                        'sanitize_callback' => 'absint',
                    ),
                    'per_page' => array(
                        'description' => __( 'Number of items per page.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => false,
                        'default'     => 10,
                        'sanitize_callback' => 'absint',
                    ),
                ),
            ));

            register_rest_route( $this->namespace, '/award-badge-rank', array(
                'methods'  => WP_REST_Server::CREATABLE,
                'callback' => array( $this, 'award_badge_rank' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'user_id' => array(
                        'description' => __( 'User ID to award badge/rank to.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => true,
                        'sanitize_callback' => 'absint',
                    ),
                    'award_type' => array(
                        'description' => __( 'Type of award: badge, rank, or both.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => true,
                        'enum'        => array( 'badge', 'rank', 'both' ),
                    ),
                    'badge_id' => array(
                        'description' => __( 'Badge ID to award.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => false,
                        'sanitize_callback' => 'absint',
                    ),
                    'rank_id' => array(
                        'description' => __( 'Rank ID to award.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => false,
                        'sanitize_callback' => 'absint',
                    ),
                ),
            ));

            register_rest_route( $this->namespace, '/remove-badge-rank', array(
                'methods'  => WP_REST_Server::CREATABLE,
                'callback' => array( $this, 'remove_badge_rank' ),
                'permission_callback' => array( $this, 'mycred_dashboard_can_manage' ),
                'args' => array(
                    'user_id' => array(
                        'description' => __( 'User ID to remove badge/rank from.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => true,
                        'sanitize_callback' => 'absint',
                    ),
                    'award_type' => array(
                        'description' => __( 'Type to remove: badge, rank, or both.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => true,
                        'enum'        => array( 'badge', 'rank', 'both' ),
                    ),
                    'badge_id' => array(
                        'description' => __( 'Badge ID to remove.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => false,
                        'sanitize_callback' => 'absint',
                    ),
                    'rank_id' => array(
                        'description' => __( 'Rank ID to remove.', 'mycred' ),
                        'type'        => 'integer',
                        'required'    => false,
                        'sanitize_callback' => 'absint',
                    ),
                ),
            ));
        }

        public function mycred_dashboard_can_manage() {
            return current_user_can( 'list_users' ) || current_user_can( 'manage_options' );
        }

        private function get_default_settings() {
            return array(
                'loyaltyMetricsHub'     => true,
                'woocommerceMetricsHub' => true,
                'pointsDistribution'    => true,
                'recentActivity'        => true,
                'quickActions'          => true,
                'topMembers'            => true,
            );
        }

        public function get_dashboard_settings( WP_REST_Request $request ) {
            $settings = get_option( 'mycred_dashboard_settings', array() );
            if ( empty( $settings ) ) {
                $settings = $this->get_default_settings();
            }
            return rest_ensure_response( $settings );
        }

        public function save_dashboard_settings( WP_REST_Request $request ) {
            $settings = $request->get_param( 'settings' );
            if ( ! is_array( $settings ) ) {
                return new WP_Error( 'invalid_settings', __( 'Settings must be an array.', 'mycred' ), array( 'status' => 400 ) );
            }
            update_option( 'mycred_dashboard_settings', $settings );
            return rest_ensure_response( array( 'success' => true, 'settings' => $settings ) );
        }

        public function search_users( WP_REST_Request $request ) {
            $search   = $request->get_param( 'search' );
            $per_page = absint( $request->get_param( 'per_page' ) ?: 10 );

            $query = new WP_User_Query( array(
                'number'         => $per_page,
                'search'         => '*' . esc_attr( $search ) . '*',
                'search_columns' => array( 'user_login', 'user_nicename', 'user_email', 'display_name' ),
                'fields'         => array( 'ID', 'user_login', 'user_nicename', 'user_email', 'display_name' ),
            ) );

            $users = array();
            foreach ( (array) $query->get_results() as $u ) {
                $users[] = mycred_dashboard_format_user( get_user_by( 'id', $u->ID ) );
            }

            return rest_ensure_response( $users );
        }

        public function get_user( WP_REST_Request $request ) {
            $id = absint( $request->get_param( 'id' ) );
            $user = get_user_by( 'id', $id );
            if ( ! $user ) {
                return new WP_Error( 'mycred_user_not_found', __( 'User not found.', 'mycred' ), array( 'status' => 404 ) );
            }

            $point_type = $request->get_param( 'point_type' );
            $response = mycred_dashboard_format_user( $user, true, $point_type );

            $earned_badges = array();
            $badge_ids = mycred_get_user_meta( $id, 'mycred_badge_ids', '', true );
            
            if ( ! empty( $badge_ids ) && is_array( $badge_ids ) ) {
                foreach ( $badge_ids as $badge_id => $value ) {
                    $badge_id = absint( $badge_id );
                    if ( $badge_id > 0 ) {
                        $badge_post = get_post( $badge_id );
                        if ( $badge_post && $badge_post->post_type === 'mycred_badge' ) {

                            $user_meta_key = 'mycred_badge' . $badge_id;
                            $level = mycred_get_user_meta( $id, $user_meta_key, '', true );
                            $level = is_numeric( $level ) ? intval( $level ) : 0;

                            // Get badge "Default Image" from main_image post meta
                            // (same field myCRED Badge object reads for main_image_url)
                            $badge_image_url = null;
                            $main_image = get_post_meta( $badge_id, 'main_image', true );
                            if ( ! empty( $main_image ) ) {
                                if ( is_numeric( $main_image ) ) {
                                    // It's an attachment ID
                                    $badge_image_url = wp_get_attachment_url( absint( $main_image ) );
                                } else {
                                    // It's a direct URL
                                    $badge_image_url = esc_url_raw( $main_image );
                                }
                            }

                            
                            $earned_badges[] = array(
                                'id'        => $badge_id,
                                'title'     => $badge_post->post_title,
                                'level'     => $level,
                                'image_url' => $badge_image_url ?: null,
                            );
                        }
                    }
                }
            }
            $response['earned_badges'] = $earned_badges;

            // Get user's rank for their active point type
            $earned_rank = null;
            $point_type = isset( $response['point_type'] ) ? $response['point_type'] : MYCRED_DEFAULT_TYPE_KEY;
            
            if ( function_exists( 'mycred_get_users_rank_id' ) ) {
                $rank_id = mycred_get_users_rank_id( $id, $point_type );
                if ( is_numeric( $rank_id ) && intval($rank_id) > 0 ) {
                    $rank_post = get_post( intval($rank_id) );
                    if ( $rank_post ) {
                        $rank_image_url = null;
                        $rank_thumb_id  = get_post_thumbnail_id( intval($rank_id) );
                        if ( $rank_thumb_id ) {
                            $rank_image_url = wp_get_attachment_image_url( $rank_thumb_id, 'thumbnail' );
                        }
                        $earned_rank = array(
                            'id'        => intval($rank_id),
                            'title'     => $rank_post->post_title,
                            'image_url' => $rank_image_url ?: null,
                        );
                    }
                }
            }
            $response['earned_rank'] = $earned_rank;

            // Add addon status flags
            $response['rank_addon_enabled'] = function_exists( 'mycred_get_users_rank_id' );
            $response['badge_addon_enabled'] = function_exists( 'mycred_badge_object' ) || class_exists( 'myCRED_Badge' );

            return rest_ensure_response( $response );
        }


        public function get_user_insights( WP_REST_Request $request ) {
            global $wpdb;

            $user_id = absint( $request->get_param( 'id' ) );
            $user    = get_user_by( 'id', $user_id );

            if ( ! $user ) {
                return new WP_Error( 'mycred_user_not_found', __( 'User not found.', 'mycred' ), array( 'status' => 404 ) );
            }

            $point_type = $request->get_param( 'point_type' );
            if ( ! $point_type ) {
                $point_type = 'mycred_default';
                $settings   = mycred_get_option( 'mycred_pref_core' );
                if ( ! empty( $settings['dashboard']['dashboard_default_point'] ) ) {
                    $point_type = sanitize_key( $settings['dashboard']['dashboard_default_point'] );
                }
            } else {
                $point_type = sanitize_key( $point_type );
            }

            $range_key  = $request->get_param( 'range' );
            $start_arg  = $request->get_param( 'start' );
            $end_arg    = $request->get_param( 'end' );
            list( $start_ts, $end_ts ) = mycred_dashboard_resolve_range_bounds( $range_key, $start_arg, $end_arg );

            $nocache = $request->get_param( 'nocache' );
            $cache_group = 'mycred_dashboard';
            $cache_ttl = apply_filters( 'mycred_dashboard_cache_ttl', 300 );
            $cache_key = sprintf( 'user_insights_%d_%s_%s_%s', $user_id, $point_type, (int) $start_ts, (int) $end_ts );

            if ( empty( $nocache ) ) {
                $cached = wp_cache_get( $cache_key, $cache_group );
                if ( false !== $cached ) {
                    return rest_ensure_response( $cached );
                }
            }

            $available_types = function_exists( 'mycred_get_types' ) ? mycred_get_types() : array();
            if ( $point_type && ! empty( $available_types ) && ! isset( $available_types[ $point_type ] ) ) {
                return new WP_Error( 'invalid_point_type', __( 'Invalid point type.', 'mycred' ), array( 'status' => 400 ) );
            }

            $range_key = $request->get_param( 'range' );
            $start_arg = $request->get_param( 'start' );
            $end_arg   = $request->get_param( 'end' );
            list( $start_ts, $end_ts ) = mycred_dashboard_resolve_range_bounds( $range_key, $start_arg, $end_arg );

            $log_table = $wpdb->prefix . 'myCRED_log' ;

            $summary      = mycred_dashboard_user_summary( $user_id, $point_type, $log_table, $start_ts, $end_ts );
            $distribution = mycred_dashboard_user_distribution( $user_id, $point_type, $log_table, $start_ts, $end_ts );
            $rankings     = mycred_dashboard_user_rankings( $user_id, $point_type, 10, $log_table, $start_ts, $end_ts );
            $response = array(
                'point_type'   => $point_type,
                'summary'      => $summary,
                'distribution' => $distribution,
                'top_members'  => $rankings,
                'range'        => array(
                    'key'   => $range_key ? strtolower( $range_key ) : 'all',
                    'start' => $start_ts,
                    'end'   => $end_ts,
                ),
            );

            if ( empty( $nocache ) ) {
                wp_cache_set( $cache_key, $response, $cache_group, $cache_ttl );
            }

            return rest_ensure_response( $response );
        }

        public function dashboard_overview( WP_REST_Request $request ) {
            global $wpdb;

            $requested_pt = $request->get_param( 'point_type' );
            $requested_range = $request->get_param( 'range' );
            $point_type = $requested_pt;
            if ( ! $point_type ) {
                $point_type = 'mycred_default';
                $mycred_pref_core = mycred_get_option( 'mycred_pref_core' );
                if ( ! empty( $mycred_pref_core['dashboard']['dashboard_default_point'] ) ) {
                    $point_type = sanitize_key( $mycred_pref_core['dashboard']['dashboard_default_point'] );
                }
            } else {
                $point_type = sanitize_key( $point_type );
            }

            $range_key = $request->get_param( 'range' );
            $start_arg = $request->get_param( 'start' );
            $end_arg = $request->get_param( 'end' );
            list( $start_ts, $end_ts ) = mycred_dashboard_resolve_range_bounds( $range_key, $start_arg, $end_arg );

            $nocache = $request->get_param( 'nocache' );
            $cache_group = 'mycred_dashboard';
            $cache_ttl = apply_filters( 'mycred_dashboard_cache_ttl', 300 );
            $cache_key = sprintf( 'dashboard_overview_%s_%s_%s', $point_type, (int) $start_ts, (int) $end_ts );
            if ( empty( $nocache ) ) {
                $cached = wp_cache_get( $cache_key, $cache_group );
                if ( false !== $cached ) {
                    return rest_ensure_response( $cached );
                }
            }

            if ( $requested_range === 'custom' ) {
                $start = $request->get_param( 'start' );
                $end = $request->get_param( 'end' );
                if ( $start && $end ) {
                    $requested_range = array( 'start' => $start, 'end' => $end );
                }
            }

            $log_table = $wpdb->prefix . 'myCRED_log' ;

            $dashboard_settings = get_option( 'mycred_dashboard_settings', array() );
            if ( empty( $dashboard_settings ) ) {
                $dashboard_settings = $this->get_default_settings();
            }
            $is_woocommerce_active = class_exists( 'WooCommerce' );
            
            $loyalty_metrics = null;
            $woocommerce_metrics = null;
            $pointsDistribution = null;
            $recentActivity = null;
            $topMembers = null;
            
            if ( ! empty( $dashboard_settings['loyaltyMetricsHub'] ) ) {
                $loyalty_metrics = mycred_dashboard_compute_loyalty_metrics( $requested_range, $point_type, $log_table );
            }

            if ( $is_woocommerce_active && ! empty( $dashboard_settings['woocommerceMetricsHub'] ) ) {
                $woocommerce_metrics = mycred_dashboard_compute_woocommerce_metrics( $requested_range, $point_type, $log_table );
            }

            if ( ! empty( $dashboard_settings['pointsDistribution'] ) ) {
                $pointsDistribution = mycred_dashboard_pointsDistribution( $requested_range, $point_type, $log_table );
            }

            if ( ! empty( $dashboard_settings['recentActivity'] ) ) {
                $recentActivity = mycred_dashboard_recent_activities( $requested_range, $point_type, $log_table );
            }

            if ( ! empty( $dashboard_settings['topMembers'] ) ) {
                $topMembers = mycred_dashboard_top_members( $requested_range, $point_type, $log_table );
            }

            $response = array();
            if ( $loyalty_metrics !== null ) {
                $response['loyalty'] = $loyalty_metrics;
            }
            if ( $woocommerce_metrics !== null ) {
                $response['woocommerce'] = $woocommerce_metrics;
            }
            if ( $pointsDistribution !== null ) {
                $mycred_pref_core = mycred_get_option( 'mycred_pref_core' );
                $settings = isset( $mycred_pref_core['dashboard'] ) ? $mycred_pref_core['dashboard'] : array(); 
                $response['chart'] = array(
                    'type' => isset( $settings['dashboard_chart_type'] ) ? $settings['dashboard_chart_type'] : 'bar',
                    'data' => $pointsDistribution
                );
            }
            if ( $recentActivity !== null ) {
                $response['recentActivity'] = $recentActivity;
            }
            if ( $topMembers !== null ) {
                $response['topMembers'] = $topMembers;
            }

            $response['toolkit_pro_enabled'] = class_exists( 'myCRED_Toolkit_Pro' );

            if ( empty( $nocache ) ) {
                wp_cache_set( $cache_key, $response, $cache_group, $cache_ttl );
            }

            return rest_ensure_response( $response );
        }

        public function award_points( WP_REST_Request $request ) {
            return handle_points_adjustment( $request, 'award' );
        }

        public function deduct_points( WP_REST_Request $request ) {
            return handle_points_adjustment( $request, 'deduct' );
        }

        public function reset_points( WP_REST_Request $request ) {
            global $wpdb;

            $user_id = absint( $request->get_param( 'user_id' ) );
            $point_type = $request->get_param( 'point_type' );

            if ( ! $user_id ) {
                return new WP_Error( 'invalid_user_id', __( 'Invalid user ID.', 'mycred' ), array( 'status' => 400 ) );
            }

            $user = get_user_by( 'id', $user_id );
            if ( ! $user ) {
                return new WP_Error( 'user_not_found', __( 'User not found.', 'mycred' ), array( 'status' => 404 ) );
            }

            $log_table = $wpdb->prefix . 'myCRED_log';

            if ( $point_type && $log_table ) {
                // Reset specific point type
                $point_type = sanitize_key( $point_type );
                
                // Delete logs for this user and point type
                $wpdb->delete(
                    $log_table,
                    array(
                        'user_id' => $user_id,
                        'ctype'   => $point_type,
                    ),
                    array( '%d', '%s' )
                );

                // Update usermeta - set balance to 0
                $meta_key = $point_type;
                update_user_meta( $user_id, $meta_key, 0 );

                // Also handle _total suffix if it exists
                $meta_key_total = $point_type . '_total';
                $existing_total = get_user_meta( $user_id, $meta_key_total, true );
                if ( $existing_total !== false ) {
                    update_user_meta( $user_id, $meta_key_total, 0 );
                }

            }

            return rest_ensure_response( array(
                'success' => true,
                'message' => sprintf( __( 'Points balance reset successfully for user %s.', 'mycred' ), $user->display_name ),
            ) );
        }

        public function get_user_history( WP_REST_Request $request ) {
            global $wpdb;

            $user_id = absint( $request->get_param( 'id' ) );
            $user = get_user_by( 'id', $user_id );

            if ( ! $user ) {
                return new WP_Error( 'mycred_user_not_found', __( 'User not found.', 'mycred' ), array( 'status' => 404 ) );
            }

            $point_type = $request->get_param( 'point_type' );
            if ( ! $point_type ) {
                $point_type = 'mycred_default';
                $settings = mycred_get_option( 'mycred_pref_core' );
                if ( ! empty( $settings['dashboard']['dashboard_default_point'] ) ) {
                    $point_type = sanitize_key( $settings['dashboard']['dashboard_default_point'] );
                }
            } else {
                $point_type = sanitize_key( $point_type );
            }

            $filter = $request->get_param( 'filter' ) ?: 'most_recent';
            $page = absint( $request->get_param( 'page' ) ?: 1 );
            $per_page = absint( $request->get_param( 'per_page' ) ?: 10 );
            $offset = ( $page - 1 ) * $per_page;

            $log_table = $wpdb->prefix . 'myCRED_log';

            // Build WHERE clause
            $where = $wpdb->prepare( "user_id = %d AND ctype = %s", $user_id, $point_type );

            // Build ORDER BY clause based on filter (whitelist approach for security)
            $allowed_order_by = array( 'time', 'creds' );
            $allowed_order = array( 'ASC', 'DESC' );
            $order_by = 'time';
            $order = 'DESC';
            
            switch ( $filter ) {
                case 'oldest_first':
                    $order_by = 'time';
                    $order = 'ASC';
                    break;
                case 'highest_first':
                    $order_by = 'creds';
                    $order = 'DESC';
                    break;
                case 'lowest_first':
                    $order_by = 'creds';
                    $order = 'ASC';
                    break;
                default: // most_recent
                    $order_by = 'time';
                    $order = 'DESC';
            }

            // Ensure values are in whitelist
            if ( ! in_array( $order_by, $allowed_order_by, true ) ) {
                $order_by = 'time';
            }
            if ( ! in_array( $order, $allowed_order, true ) ) {
                $order = 'DESC';
            }

            // Get total count
            $total_query = "SELECT COUNT(*) FROM {$log_table} WHERE {$where}";
            $total = $wpdb->get_var( $total_query );
            $total_pages = ceil( $total / $per_page );

            // Get items - using esc_sql for column names (whitelisted)
            $order_by_safe = esc_sql( $order_by );
            $order_safe = esc_sql( $order );
            $query = $wpdb->prepare(
                "SELECT * FROM {$log_table} WHERE {$where} ORDER BY {$order_by_safe} {$order_safe} LIMIT %d OFFSET %d",
                $per_page,
                $offset
            );

            $results = $wpdb->get_results( $query, ARRAY_A );

            // Format results
            $items = array();
            foreach ( $results as $row ) {
                // Process template tags
                $entry = $row['entry'];
                if ( function_exists( 'mycred' ) ) {
                    $mycred = mycred($point_type);
                    if ( $mycred && method_exists( $mycred, 'parse_template_tags' ) ) {
                         $log_entry = new stdClass();
                         $log_entry->ref = $row['ref'];
                         $log_entry->ref_id = $row['ref_id'];
                         $log_entry->data = maybe_unserialize( $row['data'] );
                         $entry = $mycred->parse_template_tags( $row['entry'], $log_entry );
                    } elseif ( $mycred && method_exists( $mycred, 'template_tags_general' ) ) {
                         $entry = $mycred->template_tags_general( $row['entry'] );
                    }
                }

                $items[] = array(
                    'id' => $row['id'],
                    'creds' => floatval( $row['creds'] ),
                    'entry' => $entry,
                    'time' => $row['time'],
                    'date' => $row['time'],
                    'ref' => $row['ref'],
                    'ref_id' => $row['ref_id'],
                );
            }

            return rest_ensure_response( array(
                'items' => $items,
                'total' => intval( $total ),
                'total_pages' => $total_pages,
                'page' => $page,
                'per_page' => $per_page,
            ) );
        }

        public function award_badge_rank( WP_REST_Request $request ) {
            $user_id = absint( $request->get_param( 'user_id' ) );
            $award_type = $request->get_param( 'award_type' );
            $badge_id = $request->get_param( 'badge_id' );
            $rank_id = $request->get_param( 'rank_id' );

            if ( ! $user_id ) {
                return new WP_Error( 'invalid_user_id', __( 'Invalid user ID.', 'mycred' ), array( 'status' => 400 ) );
            }

            $user = get_user_by( 'id', $user_id );
            if ( ! $user ) {
                return new WP_Error( 'user_not_found', __( 'User not found.', 'mycred' ), array( 'status' => 404 ) );
            }

            $results = array();
            $messages = array();

            if ( ( $award_type === 'badge' || $award_type === 'both' ) && $badge_id ) {
                $badge_id = absint( $badge_id );
                $badge = get_post( $badge_id );
                
                if ( ! $badge || $badge->post_type !== 'mycred_badge' ) {
                    return new WP_Error( 'invalid_badge', __( 'Invalid badge ID.', 'mycred' ), array( 'status' => 400 ) );
                }

                // Award badge using myCRED badges addon
                if ( class_exists( 'myCRED_Badge' ) ) {
                    $badge_instance = new myCRED_Badge( $badge_id );
                    if ( $badge_instance->post_id ) {
                        $badge_instance->assign( $user_id );
                        $results['badge'] = true;
                        $messages[] = sprintf( __( 'Badge "%s" awarded successfully.', 'mycred' ), get_the_title( $badge_id ) );
                    }
                } else {
                    return new WP_Error( 'badges_not_available', __( 'Badges addon is not available.', 'mycred' ), array( 'status' => 500 ) );
                }
            }

            if ( ( $award_type === 'rank' || $award_type === 'both' ) && $rank_id ) {
                $rank_id = absint( $rank_id );
                $rank = get_post( $rank_id );
                
                if ( ! $rank || $rank->post_type !== 'mycred_rank' ) {
                    return new WP_Error( 'invalid_rank', __( 'Invalid rank ID.', 'mycred' ), array( 'status' => 400 ) );
                }

                // Award rank using myCRED ranks addon
                if ( class_exists( 'myCRED_Rank' ) ) {
                    $rank_instance = new myCRED_Rank( $rank_id );
                    if ( $rank_instance->post_id ) {
                        $rank_instance->assign( $user_id );
                        $results['rank'] = true;
                        $messages[] = sprintf( __( 'Rank "%s" awarded successfully.', 'mycred' ), get_the_title( $rank_id ) );
                    }
                } else {
                    return new WP_Error( 'ranks_not_available', __( 'Ranks addon is not available.', 'mycred' ), array( 'status' => 500 ) );
                }
            }

            if ( empty( $results ) ) {
                return new WP_Error( 'nothing_to_award', __( 'No badge or rank specified to award.', 'mycred' ), array( 'status' => 400 ) );
            }

            return rest_ensure_response( array(
                'success' => true,
                'message' => implode( ' ', $messages ),
                'results' => $results,
            ) );
        }

        public function remove_badge_rank( WP_REST_Request $request ) {
            $user_id = absint( $request->get_param( 'user_id' ) );
            $award_type = $request->get_param( 'award_type' );
            $badge_id = $request->get_param( 'badge_id' );
            $rank_id = $request->get_param( 'rank_id' );

            if ( ! $user_id ) {
                return new WP_Error( 'invalid_user_id', __( 'Invalid user ID.', 'mycred' ), array( 'status' => 400 ) );
            }

            $user = get_user_by( 'id', $user_id );
            if ( ! $user ) {
                return new WP_Error( 'user_not_found', __( 'User not found.', 'mycred' ), array( 'status' => 404 ) );
            }

            $results = array();
            $messages = array();

            if ( ( $award_type === 'badge' || $award_type === 'both' ) && $badge_id ) {
                $badge_id = absint( $badge_id );
                $badge = get_post( $badge_id );
                if ( ! $badge || $badge->post_type !== 'mycred_badge' ) {
                    return new WP_Error( 'invalid_badge', __( 'Invalid badge ID.', 'mycred' ), array( 'status' => 400 ) );
                }
                // Remove badge by removing user meta keys
                $user_meta_key = 'mycred_badge' . $badge_id;
                $badge_ids = mycred_get_user_meta( $user_id, 'mycred_badge_ids', '', true );
                $removed = false;
                
                // Check if user has this badge
                $has_badge = mycred_get_user_meta( $user_id, $user_meta_key, '', false );
                if ( ! empty( $has_badge ) ) {
                    // Remove the individual badge meta
                    mycred_delete_user_meta( $user_id, $user_meta_key );
                    mycred_delete_user_meta( $user_id, $user_meta_key, '_issued_on' );
                    $removed = true;
                }
                
                // Remove from badge_ids array
                if ( is_array( $badge_ids ) && isset( $badge_ids[ $badge_id ] ) ) {
                    unset( $badge_ids[ $badge_id ] );
                    mycred_update_user_meta( $user_id, 'mycred_badge_ids', '', $badge_ids );
                    $removed = true;
                }
                
                if ( $removed ) {
                    $results['badge'] = true;
                    $messages[] = sprintf( __( 'Badge "%s" removed successfully.', 'mycred' ), get_the_title( $badge_id ) );
                } else {
                    $messages[] = sprintf( __( 'Badge "%s" was not assigned to user.', 'mycred' ), get_the_title( $badge_id ) );
                }
            }

            if ( ( $award_type === 'rank' || $award_type === 'both' ) && $rank_id ) {
                $rank_id = absint( $rank_id );
                
                if ( function_exists( 'mycred_get_rank' ) ) {
                    $rank = mycred_get_rank( $rank_id );
                    
                    if ( ! $rank ) {
                        return new WP_Error( 'invalid_rank', __( 'Invalid rank ID.', 'mycred' ), array( 'status' => 400 ) );
                    }

                    // Get rank's point type
                    $rank_point_type = get_post_meta( $rank_id, 'ctype', true );
                    if ( empty( $rank_point_type ) ) {
                        $rank_point_type = MYCRED_DEFAULT_TYPE_KEY;
                    }

                    // Check if user has this rank
                    $users_current_rank_id = mycred_get_users_rank_id( $user_id, $rank_point_type );

                    if ( intval( $users_current_rank_id ) === $rank_id ) {
                        // User has this rank, remove it
                        $rank->divest( $user_id );
                        $results['rank'] = true;
                        $messages[] = sprintf( __( 'Rank "%s" removed successfully.', 'mycred' ), get_the_title( $rank_id ) );
                    } else {
                        $messages[] = sprintf( __( 'Rank "%s" was not assigned to user.', 'mycred' ), get_the_title( $rank_id ) );
                    }
                } else {
                     // Fallback for when myCRED_Rank class/functions are not available (shouldn't happen if addon is active)
                    $rank = get_post( $rank_id );
                    if ( ! $rank || $rank->post_type !== 'mycred_rank' ) {
                        return new WP_Error( 'invalid_rank', __( 'Invalid rank ID.', 'mycred' ), array( 'status' => 400 ) );
                    }
                    
                    $current_rank = get_user_meta( $user_id, 'mycred_rank', true );
                    if ( intval( $current_rank ) === $rank_id ) {
                        update_user_meta( $user_id, 'mycred_rank', 0 );
                        $results['rank'] = true;
                        $messages[] = sprintf( __( 'Rank "%s" removed successfully.', 'mycred' ), get_the_title( $rank_id ) );
                    } else {
                        $messages[] = sprintf( __( 'Rank "%s" was not assigned to user.', 'mycred' ), get_the_title( $rank_id ) );
                    }
                }
            }

            if ( empty( $results ) ) {
                return new WP_Error( 'nothing_to_remove', __( 'No badge or rank specified to remove.', 'mycred' ), array( 'status' => 400 ) );
            }

            return rest_ensure_response( array(
                'success' => true,
                'message' => implode( ' ', $messages ),
                'results' => $results,
            ) );
        }

    }

    myCRED_Dashboard_API::instance();
endif;
