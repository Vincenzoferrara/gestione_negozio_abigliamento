<?php
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

if ( ! function_exists( 'mycred_loyalty_widget_is_pro' ) ) {
    function mycred_loyalty_widget_is_pro() {
        $is_toolkit_pro_active = false;
        $active_plugins = (array) get_option( 'active_plugins', array() );
        if ( in_array( 'mycred-toolkit-pro/mycred-toolkit-pro.php', $active_plugins, true ) ) {
            if( file_exists( WP_PLUGIN_DIR . '/mycred-toolkit-pro/includes/mycred-toolkit-plan-check.php' ) ) {
                $is_toolkit_pro_active = true;    
            }
        }
        return $is_toolkit_pro_active;
    }
}

if ( ! class_exists( 'myCRED_Loyalty_Widget_API' ) ) :

    class myCRED_Loyalty_Widget_API {

        protected static $instance = null;
        protected $namespace = 'mycred-loyalty-widget/v1';
        protected $option_name = 'mycred_loyalty_widget_settings';

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
            // GET all settings
            register_rest_route( $this->namespace, '/settings', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_settings' ),
                'permission_callback' => array( $this, 'check_permission' ),
            ));

            // POST all settings
            register_rest_route( $this->namespace, '/settings', array(
                'methods'  => WP_REST_Server::CREATABLE,
                'callback' => array( $this, 'save_settings' ),
                'permission_callback' => array( $this, 'check_permission' ),
                'args' => array(
                    'settings' => array(
                        'description' => __( 'Widget settings data.', 'mycred' ),
                        'type'        => 'object',
                        'required'    => true,
                    ),
                ),
            ));

            // GET specific section
            register_rest_route( $this->namespace, '/settings/(?P<section>[a-z]+)', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_section' ),
                'permission_callback' => array( $this, 'check_permission' ),
                'args' => array(
                    'section' => array(
                        'description' => __( 'Settings section name.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => true,
                        'sanitize_callback' => 'sanitize_key',
                    ),
                ),
            ));

            // POST specific section
            register_rest_route( $this->namespace, '/settings/(?P<section>[a-z]+)', array(
                'methods'  => WP_REST_Server::CREATABLE,
                'callback' => array( $this, 'save_section' ),
                'permission_callback' => array( $this, 'check_permission' ),
                'args' => array(
                    'section' => array(
                        'description' => __( 'Settings section name.', 'mycred' ),
                        'type'        => 'string',
                        'required'    => true,
                        'sanitize_callback' => 'sanitize_key',
                    ),
                    'data' => array(
                        'description' => __( 'Section settings data.', 'mycred' ),
                        'type'        => 'object',
                        'required'    => true,
                    ),
                ),
            ));

            // GET leaderboard
            register_rest_route( $this->namespace, '/leaderboard', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_leaderboard' ),
                'permission_callback' => array( $this, 'public_widget_endpoint_permission_callback' ),
            ));

            // GET logs
            register_rest_route( $this->namespace, '/logs', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_logs' ),
                'permission_callback' => function() {
                    return is_user_logged_in();
                },
            ));

            // GET badges
            register_rest_route( $this->namespace, '/badges', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_badges' ),
                'permission_callback' => array( $this, 'public_widget_endpoint_permission_callback' ),
            ));

            // GET coupons
            register_rest_route( $this->namespace, '/coupons', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_coupons' ),
                'permission_callback' => function() {
                    return is_user_logged_in();
                },
            ));

            // GET ranks
            register_rest_route( $this->namespace, '/ranks', array(
                'methods'  => WP_REST_Server::READABLE,
                'callback' => array( $this, 'get_ranks' ),
                'permission_callback' => array( $this, 'public_widget_endpoint_permission_callback' ),
            ));
        }

        public function check_permission() {
            return current_user_can( 'manage_options' );
        }

        public function public_widget_endpoint_permission_callback( WP_REST_Request $request ) {
            if ( ! self::visitor_can_see_widget() ) {
                return new WP_Error(
                    'rest_forbidden',
                    __( 'Loyalty widget is not available.', 'mycred' ),
                    array( 'status' => 403 )
                );
            }

            return true;
        }

        public static function visitor_can_see_widget( $settings = null ) {
            if ( null === $settings || ! is_array( $settings ) ) {
                $settings = get_option( 'mycred_loyalty_widget_settings', array() );
            }

            $general = isset( $settings['general'] ) && is_array( $settings['general'] ) ? $settings['general'] : array();

            // 1) Enable check
            $is_enabled = isset( $general['enableWidget'] ) ? (bool) $general['enableWidget'] : false;
            if ( ! $is_enabled ) {
                return false;
            }

            // 2) Visibility check
            $visibility = isset( $general['visibility'] ) ? $general['visibility'] : 'all';

            if ( 'logged_in' === $visibility && ! is_user_logged_in() ) {
                return false;
            }
            if ( 'guests' === $visibility && is_user_logged_in() ) {
                return false;
            }
            if ( 'roles' === $visibility ) {
                if ( ! is_user_logged_in() ) {
                    return false;
                }

                $allowed_roles = isset( $general['visibilityRoles'] ) && is_array( $general['visibilityRoles'] ) ? $general['visibilityRoles'] : array();
                if ( empty( $allowed_roles ) ) {
                    return false;
                }

                $user = wp_get_current_user();
                $user_roles = isset( $user->roles ) && is_array( $user->roles ) ? $user->roles : array();

                $has_role = false;
                foreach ( $user_roles as $role ) {
                    if ( in_array( $role, $allowed_roles, true ) ) {
                        $has_role = true;
                        break;
                    }
                }

                if ( ! $has_role ) {
                    return false;
                }
            }

            // 3) Scheduling check
            if ( ! empty( $general['enableDateRange'] ) ) {
                $now = current_time( 'timestamp' );

                $start_date = ! empty( $general['campaignStart'] ) ? strtotime( $general['campaignStart'] ) : 0;
                $end_date   = ! empty( $general['campaignEnd'] ) ? strtotime( $general['campaignEnd'] . ' 23:59:59' ) : PHP_INT_MAX;

                if ( $now < $start_date || $now > $end_date ) {
                    return false;
                }

                $start_time = ! empty( $general['startTime'] ) ? $general['startTime'] : '00:00';
                $end_time   = ! empty( $general['endTime'] ) ? $general['endTime'] : '23:59';

                $current_time_str = current_time( 'H:i' );
                if ( $current_time_str < $start_time || $current_time_str > $end_time ) {
                    return false;
                }
            }

            return true;
        }

        public function get_leaderboard( WP_REST_Request $request ) {
            $all_settings = get_option( $this->option_name, array() );
            $board_settings = isset( $all_settings['tabs']['boardSettings'] ) ? $all_settings['tabs']['boardSettings'] : array();
            
            $leaderboard_args = isset( $board_settings['leaderboard'] ) ? $board_settings['leaderboard'] : array();
            
            $number = isset( $leaderboard_args['numberOfUsers'] ) ? (int) $leaderboard_args['numberOfUsers'] : 10;
            $order  = isset( $leaderboard_args['rankingOrder'] ) && 'lowest_first' === $leaderboard_args['rankingOrder'] ? 'ASC' : 'DESC';
            $offset = isset( $leaderboard_args['positionOffset'] ) ? (int) $leaderboard_args['positionOffset'] : 0;
            $timeframe = isset( $leaderboard_args['timeframeFilter'] ) ? $leaderboard_args['timeframeFilter'] : 'all_time';

            // Point Type from request or settings
            $point_type = $request->get_param( 'type' );
            if ( empty( $point_type ) ) {
                $point_type = 'mycred_default';
            }

            // myCred Leaderboard Query
            $args = array(
                'number'   => $number,
                'order'    => $order,
                'offset'   => $offset,
                'type'     => $point_type,
            );

            if ( 'today' === $timeframe ) {
                $args['timeframe'] = 'today';
            } elseif ( 'this_week' === $timeframe ) {
                $args['timeframe'] = 'this-week'; // myCred use this-week
            } elseif ( 'this_month' === $timeframe ) {
                $args['timeframe'] = 'this-month'; // myCred use this-month
            }

            $results = array();
            if ( function_exists( 'mycred_get_leaderboard' ) ) {
                $leaderboard_query = mycred_get_leaderboard( $args );
                $leaderboard_query->get_leaderboard_results();
                $leaderboard = $leaderboard_query->leaderboard;

                if ( ! empty( $leaderboard ) && is_array( $leaderboard ) ) {
                    $mycred = mycred( $point_type );
                    $current_user_id = get_current_user_id();
                    $position = 1;
                    $display_options = isset( $board_settings['displayOptions'] ) ? $board_settings['displayOptions'] : array();
                    $show_avatar  = isset( $display_options['showUserAvatar'] ) ? $display_options['showUserAvatar'] : true;
                    $show_rank    = isset( $display_options['showUserRank'] ) ? $display_options['showUserRank'] : true;
                    $show_badge   = isset( $display_options['showUserBadge'] ) ? $display_options['showUserBadge'] : true;
                    $show_balance = isset( $display_options['showPointsBalance'] ) ? $display_options['showPointsBalance'] : true;

                    foreach ( $leaderboard as $row ) {
                        $user_id = $row['ID'];
                        $user_data = get_userdata( $user_id );
                        
                        // Get user rank
                        $rank_name     = '';
                        $rank_image    = '';
                        if ( $show_rank && function_exists( 'mycred_get_users_rank' ) ) {
                            // Try to get rank ID first if the function exists (often more reliable)
                            $rank = false;
                            if ( function_exists( 'mycred_get_users_rank_id' ) ) {
                                $rank = mycred_get_users_rank_id( $user_id, $point_type );
                                
                                // Fallback to global rank ID if not found
                                if ( ! $rank && 'mycred_default' !== $point_type ) {
                                    $rank = mycred_get_users_rank_id( $user_id );
                                }
                            }

                            // If we don't have a rank yet, try the main object fetcher
                            if ( ! $rank ) {
                                $rank = mycred_get_users_rank( $user_id, $point_type );
                                
                                // Fallback to default if not found and we are not on default already
                                if ( ! $rank && 'mycred_default' !== $point_type ) {
                                    $rank = mycred_get_users_rank( $user_id );
                                }
                            }

                            if ( is_object( $rank ) && isset( $rank->post_title ) ) {
                                $rank_name = $rank->post_title;
                                // Try to get rank logo/image
                                $rank_logo_id = get_post_meta( $rank->ID, 'mycred_rank_logo', true );
                                if ( $rank_logo_id ) {
                                    $rank_image = wp_get_attachment_url( $rank_logo_id );
                                }
                            } elseif ( is_numeric( $rank ) && (int) $rank > 0 ) {
                                // Rank returned as ID
                                $rank_post = get_post( $rank );
                                if ( $rank_post ) {
                                    $rank_name = $rank_post->post_title;
                                    $rank_logo_id = get_post_meta( $rank_post->ID, 'mycred_rank_logo', true );
                                    if ( $rank_logo_id ) {
                                        $rank_image = wp_get_attachment_url( $rank_logo_id );
                                    }
                                }
                            } elseif ( is_string( $rank ) ) {
                                $rank_name = $rank;
                            }
                        }

                        // Get top earned badge for this user
                        $top_badge_image = '';
                        $top_badge_title = '';
                        if ( $show_badge && function_exists( 'mycred_get_badge_ids' ) && function_exists( 'mycred_get_badge' ) ) {
                            $badge_ids = mycred_get_badge_ids();
                            foreach ( $badge_ids as $badge_id ) {
                                $badge = mycred_get_badge( $badge_id );
                                if ( $badge === false ) continue;
                                $user_level = $badge->get_users_current_level( $user_id );
                                if ( $user_level !== false ) {
                                    $top_badge_image = ! empty( $badge->main_image_url ) ? $badge->main_image_url : '';
                                    $top_badge_title = $badge->title;
                                    break; // Just take the first earned badge
                                }
                            }
                        }

                        $user_entry = array(
                            'id'              => $user_id,
                            'name'            => $user_data ? $user_data->display_name : __( 'Unknown', 'mycred' ),
                            'position'        => $position + $offset,
                            'is_current_user' => ( $user_id == $current_user_id ),
                        );

                        if ( $show_avatar ) {
                            $user_entry['avatar'] = get_avatar_url( $user_id );
                        }

                        if ( $show_rank ) {
                            $user_entry['rank']       = $rank_name;
                            $user_entry['rank_image'] = $rank_image;
                        }

                        if ( $show_badge ) {
                            $user_entry['top_badge_image'] = $top_badge_image;
                            $user_entry['top_badge_title'] = $top_badge_title;
                        }

                        if ( $show_balance ) {
                            $user_entry['balance']     = $mycred->format_creds( $row['cred'] );
                            $user_entry['raw_balance'] = $row['cred'];
                        }

                        $results[] = $user_entry;
                        $position++;
                    }
                }
            }

            return rest_ensure_response( array(
                'success' => true,
                'data'    => $results,
            ) );
        }

        public function get_logs( WP_REST_Request $request ) {
            $user_id = get_current_user_id();
            if ( ! $user_id ) {
                return new WP_Error( 'no_user', 'User not found', array( 'status' => 401 ) );
            }

            $point_type = $request->get_param( 'type' ) ?: MYCRED_DEFAULT_TYPE_KEY;
            $mycred     = mycred( $point_type );

            $log = new myCRED_Query_Log( array(
                'user_id' => $user_id,
                'number'  => 20,
                'ctype'   => $point_type
            ) );

            $results = array();
            if ( ! empty( $log->results ) ) {
                foreach ( $log->results as $entry ) {
                    $results[] = array(
                        'id'      => $entry->id,
                        'reason'  => $mycred->template_tags_general( $entry->entry ),
                        'amount'  => $mycred->format_creds( $entry->creds ),
                        'date'    => date_i18n( get_option( 'date_format' ) . ' ' . get_option( 'time_format' ), $entry->time ),
                        'type'    => ( $entry->creds >= 0 ) ? 'credit' : 'debit'
                    );
                }
            }

            return rest_ensure_response( array(
                'success' => true,
                'data'    => $results,
                'point_label' => $mycred->plural(),
            ) );
        }

        public static function merge_defaults( $settings, $defaults ) {
            $merged = $defaults;
            if ( is_array( $settings ) ) {
                foreach ( $settings as $key => $value ) {
                    if ( is_array( $value ) && isset( $merged[ $key ] ) && is_array( $merged[ $key ] ) ) {
                        $merged[ $key ] = self::merge_defaults( $value, $merged[ $key ] );
                    } else {
                        $merged[ $key ] = $value;
                    }
                }
            }
            return $merged;
        }

        public function get_default_settings() {
            return array(
                'general' => array(
                    'enableWidget' => false,
                    'widgetPosition' => 'bottom-right',
                    'displayMode' => 'popup',
                    'enableDateRange' => false,
                    'campaignStart' => null,
                    'campaignEnd' => null,
                    'startTime' => '00:00',
                    'endTime' => '23:59',
                    'marginTop' => 24,
                    'marginRight' => 24,
                    'marginBottom' => 24,
                    'marginLeft' => 24,
                ),
                'design' => array(
                    'showLogo' => true,
                    'backgroundColor' => '#000000',
                    'textColor' => '#FFFFFF',
                    'buttonColor' => '#000000',
                    'buttonTextColor' => '#FFFFFF',
                    'showBranding' => true,
                    'logoUrl' => plugin_dir_url( dirname( __FILE__ ) ) . 'src/assets/widget-icon/widget-logo.png',
                    'logoText' => __( 'Reward Program', 'mycred' ),
                    'launcherRadius' => 45,
                    'launcherAnimation' => 'fade',
                    'layoutTemplate' => 'luxury',
                    'headerStyle' => 'solid',
                    'headerImageUrl' => plugin_dir_url( dirname( __FILE__ ) ) . 'src/assets/widget-icon/mycred_widget_header.png',
                    'headerOverlayOpacity' => 0,
                    'headerSubtitle' => __( 'Welcome to', 'mycred' ),
                    'programTitle' => __( 'Rewards Hub', 'mycred' ),
                    'borderRadius' => 8,
                    'showReferralOnHome' => true,
                    'navLayout' => 'grid',
                    'heroImageUrl' => plugin_dir_url( dirname( __FILE__ ) ) . 'src/assets/widget-icon/default-logo1.svg',
                ),
                'content' => array(
                    'guest' => array(
                        'welcomeMessage' => __( 'Welcome! Sign up to start earning rewards', 'mycred' ),
                        'earnLabel' => __( 'Earn', 'mycred' ),
                        'redeemLabel' => __( 'Redeem', 'mycred' ),
                        'boardLabel' => __( 'Board', 'mycred' ),
                        'logsLabel' => __( 'History', 'mycred' ),
                        'profileLabel' => __( 'Profile', 'mycred' ),
                        'ranksLabel' => __( 'Ranks', 'mycred' ),
                        'badgesLabel' => __( 'Badges', 'mycred' ),
                        'earnMessage' => __( 'Complete actions to earn points', 'mycred' ),
                        'redeemMessage' => __( 'Login to redeem rewards', 'mycred' ),
                        'boardMessage' => __( 'See the leaderboard', 'mycred' ),
                        'logsMessage' => __( 'Track your points history', 'mycred' ),
                        'profileMessage' => __( 'Manage your profile', 'mycred' ),
                        'ranksMessage' => __( 'View member ranks', 'mycred' ),
                        'badgesMessage' => __( 'See all badges', 'mycred' ),
                        'referralMessage' => __( 'Refer friends and earn bonus points', 'mycred' ),
                        'joinCardTitle' => __( 'Join the Circle', 'mycred' ),
                        'joinCardDescription' => __( 'First access to rare rewards, exclusive events, and privileges reserved for members.', 'mycred' ),
                        'joinRedirect' => '',
                        'loginRedirect' => '',
                    ),
                    'member' => array(
                        'welcomeMessage' => __( 'Welcome back! Keep earning rewards', 'mycred' ),
                        'earnLabel' => __( 'Earn', 'mycred' ),
                        'redeemLabel' => __( 'Redeem', 'mycred' ),
                        'boardLabel' => __( 'Board', 'mycred' ),
                        'logsLabel' => __( 'History', 'mycred' ),
                        'profileLabel' => __( 'Profile', 'mycred' ),
                        'ranksLabel' => __( 'Ranks', 'mycred' ),
                        'badgesLabel' => __( 'Badges', 'mycred' ),
                        'earnMessage' => __( 'Check out new ways to earn points', 'mycred' ),
                        'redeemMessage' => __( 'Redeem your points for exclusive rewards', 'mycred' ),
                        'boardMessage' => __( 'Check your standing', 'mycred' ),
                        'logsMessage' => __( 'Track your points history', 'mycred' ),
                        'profileMessage' => __( 'Update your details', 'mycred' ),
                        'ranksMessage' => __( 'Explore your ranks', 'mycred' ),
                        'badgesMessage' => __( 'View your earned badges', 'mycred' ),
                        'referralMessage' => __( 'Share your referral link and earn together', 'mycred' ),
                        'showDashboardButton' => true,
                        'dashboardButtonText' => __( 'Dashboard', 'mycred' ),
                        'dashboardRedirect' => '',
                    ),
                ),
                'tabs' => array(
                    'boardSettings' => array(
                        'leaderboard' => array(
                            'numberOfUsers' => 10,
                            'rankingOrder' => 'highest_first',
                            'positionOffset' => 0,
                            'timeframeFilter' => 'all_time',
                            'emptyMessage' => __( 'No users to display', 'mycred' ),
                        ),
                        'displayOptions' => array(
                            'showUserAvatar' => true,
                            'showUserRank' => true,
                            'showUserBadge' => true,
                            'showPointsBalance' => true,
                            'highlightCurrentUser' => true,
                            'filterByPointType' => false,
                        ),
                    ),
                    'tabControls' => array(
                        'earn' => true,
                        'redeem' => true,
                        'profile' => true,
                        'board' => true,
                        'logs' => true,
                        'badges' => true,
                        'ranks' => true,
                        'faq' => true,
                    ),
                ),
                'faq' => array(
                    'screenTitle' => __( 'FAQs', 'mycred' ),
                    'items' => array(),
                ),
                'eventtriggers' => array(
                    'enableHooks' => true,
                    'enableEventTriggers' => false,
                    'wordpressHooks' => array(),
                    'woocommerceHooks' => array(),
                    'buddypressHooks' => array(),
                    'forumHooks' => array(),
                ),
            );
        }

        public function get_settings( WP_REST_Request $request ) {
            $settings = get_option( $this->option_name, array() );
            
            if ( empty( $settings ) ) {
                $settings = $this->get_default_settings();
            } else {
                $settings = self::merge_defaults( $settings, $this->get_default_settings() );
            }

            if ( isset( $settings['design'] ) && is_array( $settings['design'] ) ) {
                $settings['design']['layoutTemplate'] = $this->normalize_layout_template(
                    isset( $settings['design']['layoutTemplate'] ) ? $settings['design']['layoutTemplate'] : 'luxury'
                );
            }
            
            return rest_ensure_response( array(
                'success' => true,
                'settings' => $settings,
            ) );
        }

        public function save_settings( WP_REST_Request $request ) {
            $settings = $request->get_param( 'settings' );
            
            if ( ! is_array( $settings ) ) {
                return new WP_Error(
                    'invalid_settings',
                    __( 'Settings must be an array.', 'mycred' ),
                    array( 'status' => 400 )
                );
            }

            $sanitized_settings = $this->sanitize_settings( $settings );
            update_option( $this->option_name, $sanitized_settings );

            return rest_ensure_response( array(
                'success' => true,
                'message' => __( 'Settings saved successfully.', 'mycred' ),
                'settings' => $sanitized_settings,
            ) );
        }

        public function get_section( WP_REST_Request $request ) {
            $section = $request->get_param( 'section' );
            $all_settings = get_option( $this->option_name, array() );

            if ( empty( $all_settings ) ) {
                $all_settings = $this->get_default_settings();
            } else {
                $all_settings = self::merge_defaults( $all_settings, $this->get_default_settings() );
            }

            if ( ! isset( $all_settings[ $section ] ) ) {
                return new WP_Error(
                    'invalid_section',
                    __( 'Invalid settings section.', 'mycred' ),
                    array( 'status' => 404 )
                );
            }

            return rest_ensure_response( array(
                'success' => true,
                'data' => $all_settings[ $section ],
            ) );
        }

        public function save_section( WP_REST_Request $request ) {
            $section = $request->get_param( 'section' );
            $data = $request->get_param( 'data' );

            if ( ! is_array( $data ) ) {
                return new WP_Error(
                    'invalid_data',
                    __( 'Section data must be an array.', 'mycred' ),
                    array( 'status' => 400 )
                );
            }

            $all_settings = get_option( $this->option_name, array() );
            
            if ( empty( $all_settings ) ) {
                $all_settings = $this->get_default_settings();
            }

            // Sanitize section data
            $sanitized_data = $this->sanitize_section( $section, $data );
            $all_settings[ $section ] = $sanitized_data;

            update_option( $this->option_name, $all_settings );

            return rest_ensure_response( array(
                'success' => true,
                'message' => sprintf( __( '%s settings saved successfully.', 'mycred' ), ucfirst( $section ) ),
                'data' => $sanitized_data,
            ) );
        }

        private function sanitize_settings( $settings ) {
            $sanitized = array();

            foreach ( $settings as $section => $data ) {
                $sanitized[ sanitize_key( $section ) ] = $this->sanitize_section( $section, $data );
            }

            return $sanitized;
        }

        private function sanitize_section( $section, $data ) {
            if ( ! is_array( $data ) ) {
                return array();
            }

            switch ( $section ) {
                case 'general':
                    return $this->sanitize_general_settings( $data );
                case 'design':
                    return $this->sanitize_design_settings( $data );
                case 'content':
                    return $this->sanitize_content_settings( $data );
                case 'tabs':
                    return $this->sanitize_tabs_settings( $data );
                case 'faq':
                    return $this->sanitize_faq_settings( $data );
                case 'eventtriggers':
                    return $this->sanitize_event_triggers_settings( $data );
                default:
                    return $data;
            }
        }

        private function sanitize_general_settings( $data ) {
            return array(
                'enableWidget' => isset( $data['enableWidget'] ) ? (bool) $data['enableWidget'] : false,
                'widgetPosition' => isset( $data['widgetPosition'] ) ? sanitize_key( $data['widgetPosition'] ) : 'bottom-right',
                'displayMode' => isset( $data['displayMode'] ) ? sanitize_key( $data['displayMode'] ) : 'popup',
                'enableDateRange' => isset( $data['enableDateRange'] ) ? (bool) $data['enableDateRange'] : false,
                'campaignStart' => isset( $data['campaignStart'] ) ? sanitize_text_field( $data['campaignStart'] ) : null,
                'campaignEnd' => isset( $data['campaignEnd'] ) ? sanitize_text_field( $data['campaignEnd'] ) : null,
                'startTime' => isset( $data['startTime'] ) ? sanitize_text_field( $data['startTime'] ) : '00:00',
                'endTime' => isset( $data['endTime'] ) ? sanitize_text_field( $data['endTime'] ) : '23:59',
                'marginTop' => isset( $data['marginTop'] ) ? absint( $data['marginTop'] ) : 24,
                'marginRight' => isset( $data['marginRight'] ) ? absint( $data['marginRight'] ) : 24,
                'marginBottom' => isset( $data['marginBottom'] ) ? absint( $data['marginBottom'] ) : 24,
                'marginLeft' => isset( $data['marginLeft'] ) ? absint( $data['marginLeft'] ) : 24,
                'visibility' => isset( $data['visibility'] ) ? sanitize_text_field( $data['visibility'] ) : 'all',
                'visibilityRoles' => isset( $data['visibilityRoles'] ) && is_array( $data['visibilityRoles'] ) ? array_map( 'sanitize_text_field', $data['visibilityRoles'] ) : array(),
            );
        }

        private function normalize_layout_template( $template ) {
            $allowed  = array( 'luxury', 'modern' );
            $template = is_string( $template ) ? sanitize_key( $template ) : 'luxury';
            if ( ! in_array( $template, $allowed, true ) ) {
                return 'luxury';
            }
            return $template;
        }

        private function sanitize_design_settings( $data ) {
            $layout_template = $this->normalize_layout_template(
                isset( $data['layoutTemplate'] ) ? $data['layoutTemplate'] : 'luxury'
            );
            $header_styles   = array( 'solid', 'image' );
            $nav_layouts     = array( 'grid', 'list' );

            $header_style = isset( $data['headerStyle'] ) ? sanitize_key( $data['headerStyle'] ) : 'solid';
            if ( ! in_array( $header_style, $header_styles, true ) ) {
                $header_style = 'solid';
            }

            $nav_layout = isset( $data['navLayout'] ) ? sanitize_key( $data['navLayout'] ) : 'list';
            if ( ! in_array( $nav_layout, $nav_layouts, true ) ) {
                $nav_layout = 'list';
            }

            $overlay = isset( $data['headerOverlayOpacity'] ) ? floatval( $data['headerOverlayOpacity'] ) : 0;
            if ( $overlay < 0 ) {
                $overlay = 0;
            } elseif ( $overlay > 1 ) {
                $overlay = 1;
            }

            $border_radius = isset( $data['borderRadius'] ) ? absint( $data['borderRadius'] ) : 8;
            if ( $border_radius < 8 ) {
                $border_radius = 8;
            } elseif ( $border_radius > 24 ) {
                $border_radius = 24;
            }

            return array(
                'showLogo' => isset( $data['showLogo'] ) ? (bool) $data['showLogo'] : false,
                'backgroundColor' => isset( $data['backgroundColor'] ) ? sanitize_hex_color( $data['backgroundColor'] ) : '#000000',
                'textColor' => isset( $data['textColor'] ) ? sanitize_hex_color( $data['textColor'] ) : '#FFFFFF',
                'buttonColor' => isset( $data['buttonColor'] ) ? sanitize_hex_color( $data['buttonColor'] ) : '#000000',
                'buttonTextColor' => isset( $data['buttonTextColor'] ) ? sanitize_hex_color( $data['buttonTextColor'] ) : '#FFFFFF',
                'showBranding' => isset( $data['showBranding'] ) ? (bool) $data['showBranding'] : true,
                'logoUrl' => isset( $data['logoUrl'] ) ? esc_url_raw( $data['logoUrl'] ) : '',
                'logoText' => isset( $data['logoText'] ) ? sanitize_text_field( $data['logoText'] ) : __( 'Reward Program', 'mycred' ),
                'launcherRadius' => isset( $data['launcherRadius'] ) ? absint( $data['launcherRadius'] ) : 45,
                'launcherAnimation' => isset( $data['launcherAnimation'] ) ? sanitize_key( $data['launcherAnimation'] ) : 'fade',
                'layoutTemplate' => $layout_template,
                'headerStyle' => $header_style,
                'headerImageUrl' => isset( $data['headerImageUrl'] ) ? esc_url_raw( $data['headerImageUrl'] ) : '',
                'headerOverlayOpacity' => $overlay,
                'headerSubtitle' => isset( $data['headerSubtitle'] ) ? sanitize_text_field( $data['headerSubtitle'] ) : __( 'Welcome to', 'mycred' ),
                'programTitle' => isset( $data['programTitle'] ) ? sanitize_text_field( $data['programTitle'] ) : __( 'Rewards Hub', 'mycred' ),
                'borderRadius' => $border_radius,
                'showTiersOnHome' => isset( $data['showTiersOnHome'] ) ? (bool) $data['showTiersOnHome'] : false,
                'showReferralOnHome' => isset( $data['showReferralOnHome'] ) ? (bool) $data['showReferralOnHome'] : true,
                'navLayout' => $nav_layout,
                'heroImageUrl' => isset( $data['heroImageUrl'] ) ? esc_url_raw( $data['heroImageUrl'] ) : '',
            );
        }

        private function limit_words( $string, $limit = 2 ) {
            $words = explode( ' ', trim( $string ) );
            if ( count( $words ) > $limit ) {
                return implode( ' ', array_slice( $words, 0, $limit ) );
            }
            return $string;
        }

        private function sanitize_content_settings( $data ) {
            $sanitized = array();

            if ( isset( $data['guest'] ) && is_array( $data['guest'] ) ) {
                $sanitized['guest'] = array(
                    'welcomeMessage' => isset( $data['guest']['welcomeMessage'] ) ? sanitize_text_field( $data['guest']['welcomeMessage'] ) : '',
                    'earnLabel' => isset( $data['guest']['earnLabel'] ) ? $this->limit_words( sanitize_text_field( $data['guest']['earnLabel'] ) ) : '',
                    'redeemLabel' => isset( $data['guest']['redeemLabel'] ) ? $this->limit_words( sanitize_text_field( $data['guest']['redeemLabel'] ) ) : '',
                    'boardLabel' => isset( $data['guest']['boardLabel'] ) ? $this->limit_words( sanitize_text_field( $data['guest']['boardLabel'] ) ) : '',
                    'logsLabel' => isset( $data['guest']['logsLabel'] ) ? $this->limit_words( sanitize_text_field( $data['guest']['logsLabel'] ) ) : '',
                    'profileLabel' => isset( $data['guest']['profileLabel'] ) ? $this->limit_words( sanitize_text_field( $data['guest']['profileLabel'] ) ) : '',
                    'ranksLabel' => isset( $data['guest']['ranksLabel'] ) ? $this->limit_words( sanitize_text_field( $data['guest']['ranksLabel'] ) ) : '',
                    'badgesLabel' => isset( $data['guest']['badgesLabel'] ) ? $this->limit_words( sanitize_text_field( $data['guest']['badgesLabel'] ) ) : '',
                    'earnMessage' => isset( $data['guest']['earnMessage'] ) ? sanitize_text_field( $data['guest']['earnMessage'] ) : '',
                    'redeemMessage' => isset( $data['guest']['redeemMessage'] ) ? sanitize_text_field( $data['guest']['redeemMessage'] ) : '',
                    'referralMessage' => isset( $data['guest']['referralMessage'] ) ? sanitize_text_field( $data['guest']['referralMessage'] ) : '',
                    'joinRedirect' => isset( $data['guest']['joinRedirect'] ) ? esc_url_raw( $data['guest']['joinRedirect'] ) : '',
                    'loginRedirect' => isset( $data['guest']['loginRedirect'] ) ? esc_url_raw( $data['guest']['loginRedirect'] ) : '',
                    'joinButtonText' => isset( $data['guest']['joinButtonText'] ) ? sanitize_text_field( $data['guest']['joinButtonText'] ) : '',
                    'loginButtonText' => isset( $data['guest']['loginButtonText'] ) ? sanitize_text_field( $data['guest']['loginButtonText'] ) : '',
                    'joinCardTitle' => isset( $data['guest']['joinCardTitle'] ) ? sanitize_text_field( $data['guest']['joinCardTitle'] ) : '',
                    'joinCardDescription' => isset( $data['guest']['joinCardDescription'] ) ? sanitize_textarea_field( $data['guest']['joinCardDescription'] ) : '',
                    'boardMessage' => isset( $data['guest']['boardMessage'] ) ? sanitize_text_field( $data['guest']['boardMessage'] ) : '',
                    'logsMessage' => isset( $data['guest']['logsMessage'] ) ? sanitize_text_field( $data['guest']['logsMessage'] ) : '',
                    'profileMessage' => isset( $data['guest']['profileMessage'] ) ? sanitize_text_field( $data['guest']['profileMessage'] ) : '',
                    'ranksMessage' => isset( $data['guest']['ranksMessage'] ) ? sanitize_text_field( $data['guest']['ranksMessage'] ) : '',
                    'badgesMessage' => isset( $data['guest']['badgesMessage'] ) ? sanitize_text_field( $data['guest']['badgesMessage'] ) : '',
                );
            }

            if ( isset( $data['member'] ) && is_array( $data['member'] ) ) {
                $sanitized['member'] = array(
                    'welcomeMessage' => isset( $data['member']['welcomeMessage'] ) ? sanitize_text_field( $data['member']['welcomeMessage'] ) : '',
                    'earnLabel' => isset( $data['member']['earnLabel'] ) ? $this->limit_words( sanitize_text_field( $data['member']['earnLabel'] ) ) : '',
                    'redeemLabel' => isset( $data['member']['redeemLabel'] ) ? $this->limit_words( sanitize_text_field( $data['member']['redeemLabel'] ) ) : '',
                    'boardLabel' => isset( $data['member']['boardLabel'] ) ? $this->limit_words( sanitize_text_field( $data['member']['boardLabel'] ) ) : '',
                    'logsLabel' => isset( $data['member']['logsLabel'] ) ? $this->limit_words( sanitize_text_field( $data['member']['logsLabel'] ) ) : '',
                    'profileLabel' => isset( $data['member']['profileLabel'] ) ? $this->limit_words( sanitize_text_field( $data['member']['profileLabel'] ) ) : '',
                    'ranksLabel' => isset( $data['member']['ranksLabel'] ) ? $this->limit_words( sanitize_text_field( $data['member']['ranksLabel'] ) ) : '',
                    'badgesLabel' => isset( $data['member']['badgesLabel'] ) ? $this->limit_words( sanitize_text_field( $data['member']['badgesLabel'] ) ) : '',
                    'earnMessage' => isset( $data['member']['earnMessage'] ) ? sanitize_text_field( $data['member']['earnMessage'] ) : '',
                    'redeemMessage' => isset( $data['member']['redeemMessage'] ) ? sanitize_text_field( $data['member']['redeemMessage'] ) : '',
                    'referralMessage' => isset( $data['member']['referralMessage'] ) ? sanitize_text_field( $data['member']['referralMessage'] ) : '',
                    'showDashboardButton' => ! isset( $data['member']['showDashboardButton'] ) || (bool) $data['member']['showDashboardButton'],
                    'dashboardButtonText' => isset( $data['member']['dashboardButtonText'] ) ? sanitize_text_field( $data['member']['dashboardButtonText'] ) : '',
                    'boardMessage' => isset( $data['member']['boardMessage'] ) ? sanitize_text_field( $data['member']['boardMessage'] ) : '',
                    'logsMessage' => isset( $data['member']['logsMessage'] ) ? sanitize_text_field( $data['member']['logsMessage'] ) : '',
                    'profileMessage' => isset( $data['member']['profileMessage'] ) ? sanitize_text_field( $data['member']['profileMessage'] ) : '',
                    'ranksMessage' => isset( $data['member']['ranksMessage'] ) ? sanitize_text_field( $data['member']['ranksMessage'] ) : '',
                    'badgesMessage' => isset( $data['member']['badgesMessage'] ) ? sanitize_text_field( $data['member']['badgesMessage'] ) : '',
                    'dashboardRedirect' => isset( $data['member']['dashboardRedirect'] ) ? esc_url_raw( $data['member']['dashboardRedirect'] ) : '',
                );
            }

            return $sanitized;
        }

        private function sanitize_tabs_settings( $data ) {
            $sanitized = array();

            if ( isset( $data['boardSettings'] ) && is_array( $data['boardSettings'] ) ) {
                $sanitized['boardSettings'] = array();

                if ( isset( $data['boardSettings']['leaderboard'] ) ) {
                    $sanitized['boardSettings']['leaderboard'] = array(
                        'numberOfUsers' => isset( $data['boardSettings']['leaderboard']['numberOfUsers'] ) ? absint( $data['boardSettings']['leaderboard']['numberOfUsers'] ) : 10,
                        'rankingOrder' => isset( $data['boardSettings']['leaderboard']['rankingOrder'] ) ? sanitize_key( $data['boardSettings']['leaderboard']['rankingOrder'] ) : 'highest_first',
                        'positionOffset' => isset( $data['boardSettings']['leaderboard']['positionOffset'] ) ? absint( $data['boardSettings']['leaderboard']['positionOffset'] ) : 0,
                        'timeframeFilter' => isset( $data['boardSettings']['leaderboard']['timeframeFilter'] ) ? sanitize_key( $data['boardSettings']['leaderboard']['timeframeFilter'] ) : 'all_time',
                        'emptyMessage' => isset( $data['boardSettings']['leaderboard']['emptyMessage'] ) ? sanitize_text_field( $data['boardSettings']['leaderboard']['emptyMessage'] ) : '',
                    );
                }

                if ( isset( $data['boardSettings']['displayOptions'] ) ) {
                    $sanitized['boardSettings']['displayOptions'] = array(
                        'showUserAvatar' => isset( $data['boardSettings']['displayOptions']['showUserAvatar'] ) ? (bool) $data['boardSettings']['displayOptions']['showUserAvatar'] : true,
                        'showUserRank' => isset( $data['boardSettings']['displayOptions']['showUserRank'] ) ? (bool) $data['boardSettings']['displayOptions']['showUserRank'] : true,
                        'showUserBadge' => isset( $data['boardSettings']['displayOptions']['showUserBadge'] ) ? (bool) $data['boardSettings']['displayOptions']['showUserBadge'] : true,
                        'showPointsBalance' => isset( $data['boardSettings']['displayOptions']['showPointsBalance'] ) ? (bool) $data['boardSettings']['displayOptions']['showPointsBalance'] : true,
                        'highlightCurrentUser' => isset( $data['boardSettings']['displayOptions']['highlightCurrentUser'] ) ? (bool) $data['boardSettings']['displayOptions']['highlightCurrentUser'] : true,
                        'filterByPointType' => isset( $data['boardSettings']['displayOptions']['filterByPointType'] ) ? (bool) $data['boardSettings']['displayOptions']['filterByPointType'] : false,
                    );
                }
            }

            if ( isset( $data['tabControls'] ) && is_array( $data['tabControls'] ) ) {
                $is_pro = $this->is_pro();
                $sanitized['tabControls'] = array(
                    'earn' => isset( $data['tabControls']['earn'] ) ? (bool) $data['tabControls']['earn'] : true,
                    'redeem' => ( isset( $data['tabControls']['redeem'] ) && $is_pro ) ? (bool) $data['tabControls']['redeem'] : false,
                    'profile' => isset( $data['tabControls']['profile'] ) ? (bool) $data['tabControls']['profile'] : true,
                    'board' => isset( $data['tabControls']['board'] ) ? (bool) $data['tabControls']['board'] : true,
                    'logs' => isset( $data['tabControls']['logs'] ) ? (bool) $data['tabControls']['logs'] : true,
                    'badges' => isset( $data['tabControls']['badges'] ) ? (bool) $data['tabControls']['badges'] : true,
                    'ranks' => isset( $data['tabControls']['ranks'] ) ? (bool) $data['tabControls']['ranks'] : true,
                    'faq' => isset( $data['tabControls']['faq'] ) ? (bool) $data['tabControls']['faq'] : true,
                );
            }

            return $sanitized;
        }

        private function sanitize_faq_settings( $data ) {
            $items = array();
            if ( isset( $data['items'] ) && is_array( $data['items'] ) ) {
                $count = 0;
                foreach ( $data['items'] as $item ) {
                    if ( $count >= 20 ) {
                        break;
                    }
                    if ( ! is_array( $item ) ) {
                        continue;
                    }
                    $title  = isset( $item['title'] ) ? sanitize_text_field( $item['title'] ) : '';
                    $answer = isset( $item['answer'] ) ? sanitize_textarea_field( $item['answer'] ) : '';
                    if ( '' === $title && '' === $answer ) {
                        continue;
                    }
                    $id = isset( $item['id'] ) ? sanitize_text_field( $item['id'] ) : '';
                    if ( '' === $id ) {
                        $id = uniqid( 'faq_', false );
                    }
                    $items[] = array(
                        'id'     => $id,
                        'title'  => $title,
                        'answer' => $answer,
                    );
                    $count++;
                }
            }

            return array(
                'screenTitle' => isset( $data['screenTitle'] ) ? sanitize_text_field( $data['screenTitle'] ) : __( 'FAQs', 'mycred' ),
                'items'       => $items,
            );
        }

        private function sanitize_event_triggers_settings( $data ) {
            $sanitized = array(
                'enableHooks' => isset( $data['enableHooks'] ) ? (bool) $data['enableHooks'] : true,
            );

            $hook_categories = array( 'wordpressHooks', 'woocommerceHooks', 'buddypressHooks', 'forumHooks' );
            foreach ( $hook_categories as $category ) {
                $sanitized[ $category ] = array();
                if ( isset( $data[ $category ] ) && is_array( $data[ $category ] ) ) {
                    foreach ( $data[ $category ] as $hook ) {
                        if ( ! is_array( $hook ) ) continue;
                        
                        $sanitized[ $category ][] = array(
                            'id'           => isset( $hook['id'] ) ? sanitize_text_field( $hook['id'] ) : '',
                            'point_type'   => isset( $hook['point_type'] ) ? sanitize_text_field( $hook['point_type'] ) : '',
                            'enabled'      => isset( $hook['enabled'] ) ? (bool) $hook['enabled'] : false,
                            'displayLabel' => isset( $hook['displayLabel'] ) ? sanitize_text_field( $hook['displayLabel'] ) : '',
                        );
                    }
                }
            }

            return $sanitized;
        }

        public function get_ranks( WP_REST_Request $request ) {
            $user_id = get_current_user_id();
            
            // Get point type (default to basic points)
            $point_type = $request->get_param( 'type' ) ?: MYCRED_DEFAULT_TYPE_KEY;
            $mycred     = mycred( $point_type );
            
            // Get all published ranks
            $ranks = function_exists( 'mycred_get_ranks' ) ? mycred_get_ranks( 'publish', '-1', 'ASC', $point_type ) : array();
            $results   = array();
            
            $current_rank_id = $user_id && function_exists('mycred_get_users_rank_id') ? mycred_get_users_rank_id( $user_id, $point_type ) : false;
    
            if ( ! empty( $ranks ) ) {
                foreach ( $ranks as $rank ) {
                    $results[] = array(
                        'id'           => $rank->post_id,
                        'title'        => $rank->title,
                        'image_url'    => $rank->has_logo && !empty($rank->logo_url) ? $rank->logo_url : '',
                        'minimum'      => $rank->minimum,
                        'maximum'      => $rank->maximum,
                        'is_current'   => ( $current_rank_id == $rank->post_id ),
                        'users_count'  => $rank->count
                    );
                }
            }
    
            return rest_ensure_response( array(
                'success' => true,
                'data'    => $results,
                'point_label' => $mycred->plural(),
            ) );
        }

        public function get_badges( WP_REST_Request $request ) {
            $user_id = get_current_user_id();
            
            // Get all published badges
            $badge_ids = mycred_get_badge_ids();
            $results   = array();
    
            if ( ! empty( $badge_ids ) ) {
                foreach ( $badge_ids as $badge_id ) {
    
                    $badge = mycred_get_badge( $badge_id );
                    if ( $badge === false ) continue;
    
                    // Check user's current level index for this badge
                    $user_level_index = false;
                    if ( $user_id ) {
                         $user_level_index = $badge->get_users_current_level( $user_id );
                    }

                    // Get detailed levels structure
                    $levels_data = mycred_get_badge_levels( $badge_id );
                    $formatted_levels = array();

                    if ( ! empty( $levels_data ) ) {
                        $point_types = mycred_get_types( true );
                        $references  = mycred_get_all_references();

                        foreach ( $levels_data as $index => $level_setup ) {
                            $is_earned = ( $user_level_index !== false && $user_level_index >= $index );
                            
                            $label = ! empty( $level_setup['label'] ) ? $level_setup['label'] : sprintf( __( 'Level %s', 'mycred' ), $index + 1 );

                            $level_image = $badge->main_image_url;
                            if ( ! empty( $level_setup['image_url'] ) ) {
                                $level_image = $level_setup['image_url'];
                            } elseif ( isset($badge->levels[$index]) && $badge->levels[$index]['attachment_id'] > 0 ) {
                                $level_image = wp_get_attachment_url( $badge->levels[$index]['attachment_id'] );
                            }

                            $reward_str = '';
                            if ( isset( $level_setup['reward'] ) && $level_setup['reward']['amount'] > 0 ) {
                                $mycred_r = mycred( $level_setup['reward']['type'] );
                                $reward_str = sprintf( __( 'Earn %s', 'mycred' ), $mycred_r->format_creds( $level_setup['reward']['amount'] ) );
                            }

                            $req_strs = array();
                            $requirements = isset($level_setup['requires']) ? $level_setup['requires'] : array();
                            foreach ( $requirements as $req_data ) {
                                $type_key = ! empty($req_data['type']) ? $req_data['type'] : MYCRED_DEFAULT_TYPE_KEY;
                                $mycred_p = mycred( $type_key );
                                $ref_key = isset($req_data['reference']) ? $req_data['reference'] : '';
                                $ref_label = isset( $references[$ref_key] ) ? $references[$ref_key] : $ref_key;
                                $amount = isset($req_data['amount']) ? $req_data['amount'] : 0;
                                
                                if ( isset($req_data['by']) && $req_data['by'] == 'count' ) {
                                    $req_strs[] = sprintf( _x( '%s for "%s" x %d', '"Points" for "reference" x times', 'mycred' ), $mycred_p->plural(), $ref_label, $amount );
                                } else {
                                    $req_strs[] = sprintf( _x( '%s %s for "%s"', '"Gained/Lost" "x points" for "reference"', 'mycred' ), ( ( $amount < 0 ) ? __( 'Lost', 'mycred' ) : __( 'Gained', 'mycred' ) ), $mycred_p->format_creds( $amount ), $ref_label );
                                }
                            }

                            $formatted_levels[] = array(
                                'level_index' => $index,
                                'label'       => $label,
                                'image_url'   => $level_image,
                                'is_earned'   => $is_earned,
                                'reward_text' => $reward_str,
                                'requirements'=> $req_strs
                            );
                        }
                    } else {
                         $formatted_levels[] = array(
                            'level_index' => 0,
                            'label'       => $badge->title,
                            'image_url'   => $badge->main_image_url,
                            'is_earned'   => ($user_level_index !== false),
                            'reward_text' => '',
                            'requirements'=> array()
                        );
                    }
    
                    $results[] = array(
                        'id'           => $badge_id,
                        'title'        => $badge->title,
                        'levels'       => $formatted_levels,
                        'user_id'      => $user_id
                    );
                }
            }
    
            return rest_ensure_response( array(
                'success' => true,
                'data'    => $results,
            ) );
        }

        /**
         * Get user awarded coupons
         * 
         * @since 1.0.0
         */
        public function get_coupons() {
            $user_id = get_current_user_id();
            if ( ! $user_id ) {
                return new WP_Error( 'not_logged_in', __( 'User not logged in.', 'mycred' ), array( 'status' => 401 ) );
            }

            // Also check for WooCommerce active
            if ( ! class_exists( 'WooCommerce' ) ) {
                return rest_ensure_response( array() );
            }

            $args = array(
                'post_type'      => 'shop_coupon',
                'post_status'    => 'publish',
                'posts_per_page' => -1,
                'meta_query'     => array(
                    array(
                        'key'     => 'user_id',
                        'value'   => $user_id,
                        'compare' => '='
                    )
                )
            );

            $coupons = get_posts( $args );
            $data = array();

            foreach ( $coupons as $coupon_post ) {
                $coupon_id = $coupon_post->ID;
                $discount_type = get_post_meta( $coupon_id, 'discount_type', true );
                $coupon_amount = get_post_meta( $coupon_id, 'coupon_amount', true );
                $date_expires  = get_post_meta( $coupon_id, 'date_expires', true );
                
                // Format amount based on discount type — decode HTML entities so currency symbol renders correctly in React
                $currency_symbol  = html_entity_decode( get_woocommerce_currency_symbol(), ENT_QUOTES | ENT_HTML5, 'UTF-8' );
                $formatted_amount = $coupon_amount;
                if ( $discount_type === 'percent' ) {
                    $formatted_amount .= '%';
                } else {
                    $formatted_amount = $currency_symbol . $formatted_amount;
                }

                $data[] = array(
                    'id'               => $coupon_id,
                    'code'             => $coupon_post->post_title,
                    'description'      => html_entity_decode( $coupon_post->post_excerpt, ENT_QUOTES | ENT_HTML5, 'UTF-8' ),
                    'discount_type'    => $discount_type,
                    'coupon_amount'    => $coupon_amount,
                    'formatted_amount' => $formatted_amount,
                    'date_expires'     => ! empty( $date_expires ) ? ( is_numeric( $date_expires ) ? date( get_option( 'date_format' ), $date_expires ) : $date_expires ) : '-',
                    'status'           => function_exists( 'mwp_coupon_status' ) ? mwp_coupon_status( $coupon_id ) : 'Available',
                );
            }

            return rest_ensure_response( $data );
        }

        private function is_pro() {
            $is_toolkit_pro_active = false;
            $active_plugins = (array) get_option( 'active_plugins', array() );
            if ( in_array( 'mycred-toolkit-pro/mycred-toolkit-pro.php', $active_plugins, true ) ) {
                if( file_exists( WP_PLUGIN_DIR . '/mycred-toolkit-pro/includes/mycred-toolkit-plan-check.php' ) ) {
                    $is_toolkit_pro_active = true;    
                }
            }
            return $is_toolkit_pro_active;
        }

    }

    myCRED_Loyalty_Widget_API::instance();

endif;
