<?php
if ( ! class_exists( 'myCRED_Dashboard' ) ) :
    class myCRED_Dashboard {
        
        private static $_instance = null;
        
        public static function instance() {
            if ( is_null( self::$_instance ) ) {
                self::$_instance = new self();
            }
            return self::$_instance;
        }
        
        public function __construct() {
            add_action( 'mycred_after_core_prefs', array( $this, 'mycred_dashboard_settings_page' ) );
            add_filter( 'mycred_save_core_prefs', array( $this, 'mycred_dashboard_save_settings'), 10, 3 );
            add_action( 'admin_menu', array( $this, 'mycred_dashboard_menu' ) );
            add_action( 'admin_enqueue_scripts', array( $this, 'mycred_dashboard_scripts' ) );
            add_action( 'admin_head', array( $this, 'hide_notices' ), 1 );
            $this->load_api();
        }

        public function hide_notices() {
            if ( isset( $_GET['page'] ) && $_GET['page'] === 'mycred-dashboard' ) {
                remove_all_actions( 'admin_notices' );
                remove_all_actions( 'all_admin_notices' );
                echo '<style>
                    .notice, .updated, .error, .fs-notice, .update-nag, .e-notice { 
                        display: none !important; 
                    }
                </style>';
            }
        }

        public function load_api() {
            if ( defined( 'myCRED_THIS' ) ) {
                $api_file = plugin_dir_path( myCRED_THIS ) . 'includes/dashboard/mycred-dashboard-api.php';
                if ( file_exists( $api_file ) ) {
                    require_once $api_file;
                }
            }
        }

        public function mycred_dashboard_scripts(){

            $mycred_pref_core = mycred_get_option( 'mycred_pref_core' );
            $settings = ! empty( $mycred_pref_core['dashboard'] ) ? $mycred_pref_core['dashboard'] : array();
            $settings = wp_parse_args( $settings, array( 
                'dashboard_enable'   => 1,
                'enable_user_filter' => 0
            ) );

            $rest_root  = esc_url_raw( rest_url() );
            $rest_nonce = wp_create_nonce( 'wp_rest' );
            $point_types_map = function_exists('mycred_get_types') ? mycred_get_types() : array();

            $available_point_type_keys = array_keys( $point_types_map );
            if ( ! empty( $settings['dashboard_point_types'] ) && is_array( $settings['dashboard_point_types'] ) ) {
                $settings['dashboard_point_types'] = array_values( array_intersect( $settings['dashboard_point_types'], $available_point_type_keys ) );
            }
            
            if ( ! empty( $settings['dashboard_default_point'] ) && ! array_key_exists( $settings['dashboard_default_point'], $point_types_map ) ) {
                $settings['dashboard_default_point'] = ! empty( $available_point_type_keys ) ? $available_point_type_keys[0] : '';
            }

            $active_plugins = (array) get_option( 'active_plugins', array() );
            if ( is_multisite() ) {
                $network_plugins = array_keys( (array) get_site_option( 'active_sitewide_plugins', array() ) );
                $active_plugins  = array_merge( $active_plugins, $network_plugins );
            }
            $active_plugins = apply_filters( 'active_plugins', $active_plugins );

            if ( in_array( 'woocommerce/woocommerce.php', $active_plugins, true ) ) {
                $settings['is_woocommerce_active'] = true;
            }

            if ( in_array( 'mycred-toolkit-pro/mycred-toolkit-pro.php', $active_plugins, true ) ) {
                if( file_exists( WP_PLUGIN_DIR . '/mycred-toolkit-pro/includes/mycred-toolkit-plan-check.php' ) ) {
                    $settings['is_toolkit_pro_active'] = true;    
                }
            }

            $is_badges_active = false;
            $badges = array();
            if ( class_exists( 'myCRED_Badge_Module' ) ) {
                $is_badges_active = true;

                $badge_query = new WP_Query( array(
                    'post_type'      => 'mycred_badge',
                    'posts_per_page' => -1,
                    'post_status'    => 'publish',
                    'fields'         => 'ids',
                ) );
                if ( $badge_query->have_posts() ) {
                    foreach ( $badge_query->posts as $badge_id ) {
                        $badges[] = array(
                            'id'    => $badge_id,
                            'ID'    => $badge_id,
                            'title' => get_the_title( $badge_id ),
                            'name'  => get_the_title( $badge_id ),
                        );
                    }
                }
            }

            $is_ranks_active = false;
            $ranks = array();
            if ( class_exists( 'myCRED_Ranks_Module' ) ) {
                $is_ranks_active = true;
                
                $rank_query = new WP_Query( array(
                    'post_type'      => 'mycred_rank',
                    'posts_per_page' => -1,
                    'post_status'    => 'publish',
                    'fields'         => 'ids',
                ) );
                if ( $rank_query->have_posts() ) {
                    foreach ( $rank_query->posts as $rank_id ) {
                        $ctype = get_post_meta( $rank_id, 'ctype', true );
                        $ranks[] = array(
                            'id'    => $rank_id,
                            'ID'    => $rank_id,
                            'title' => get_the_title( $rank_id ),
                            'name'  => get_the_title( $rank_id ),
                            'ctype' => $ctype ? $ctype : MYCRED_DEFAULT_TYPE_KEY,
                        );
                    }
                }
            }

            wp_register_script('mycred-dashboard-script', plugins_url('includes/dashboard/build/index.bundle.js', myCRED_THIS), array('wp-element'), '1.0.0',true );

            wp_localize_script('mycred-dashboard-script', 'mycredDashboardData', [
                'dashboard_settings' => $settings,
                'restRoot'           => $rest_root,
                'restNonce'          => $rest_nonce,
                'pointTypesMap'      => $point_types_map,
                'badges'             => $badges,
                'ranks'              => $ranks,
                'isBadgesActive'     => $is_badges_active,
                'isRanksActive'      => $is_ranks_active,
                'current_user_name'  => wp_get_current_user()->display_name,
                'current_user_avatar' => get_avatar_url( get_current_user_id(), array( 'size' => 96 ) ),
            ]);
            
        }

        public function mycred_dashboard_menu() {
            $mycred_pref_core = mycred_get_option( 'mycred_pref_core' );
            $settings = ! empty( $mycred_pref_core['dashboard'] ) ? $mycred_pref_core['dashboard'] : array();
            $settings = wp_parse_args( $settings, array( 'dashboard_enable' => 1 ) );

            
            if( ! empty( $settings['dashboard_enable'] ) ) {
                mycred_add_main_submenu( 
                    __( 'Dashboard', 'mycred' ),
                    __( 'Dashboard', 'mycred' ),
                    'manage_options', 
                    'mycred-dashboard',
                    array( $this, 'mycred_dashboard_callback' ),
                    0
                );
            }
        }

        public function mycred_dashboard_callback() {
            wp_enqueue_script('wp-element');
            wp_enqueue_script( 'mycred-dashboard-script' );
            echo '<div id="mycred-dashboard" style="margin-left:-20px"></div>';
        }
        
        /**
         * Save dashboard settings
         */
        public function mycred_dashboard_save_settings( $new_data, $post, $mycred_general ) {
             
            $dashboard = isset( $post['dashboard'] ) ? $post['dashboard'] : array();
           
            $new_data['dashboard'] = array(
                'dashboard_enable'        => ! empty( $dashboard['dashboard_enable'] ) ? 1 : 0,
                'enable_user_filter'      => ! empty( $dashboard['enable_user_filter'] ) ? 1 : 0,
                'dashboard_default_point' => ! empty( $dashboard['dashboard_default_point'] ) ? sanitize_text_field( $dashboard['dashboard_default_point'] ) : '',
            );
                 
            return $new_data;
        }
        
       
        public function mycred_dashboard_settings_page() {
            
            
            $mycred_pref_core = mycred_get_option( 'mycred_pref_core' );
            $settings = ! empty( $mycred_pref_core['dashboard'] ) ? $mycred_pref_core['dashboard'] : array();
            $settings = wp_parse_args( $settings, array( 'dashboard_enable' => 1 ) );

            
            $available_point_types = mycred_get_types();
            ?>
            
            <div class="mycred-ui-accordion">
                
                <div class="mycred-ui-accordion-header">
                    <h4 class="mycred-ui-accordion-header-title">
                        <span class="dashicons dashicons-chart-bar static mycred-ui-accordion-header-icon"></span>
                        <label><?php esc_html_e( 'Dashboard', 'mycred' ); ?></label>
                    </h4>
                    <div class="mycred-ui-accordion-header-actions hide-if-no-js">
                        <button type="button" aria-expanded="true">
                            <span class="mycred-ui-toggle-indicator" aria-hidden="true"></span>
                        </button>
                    </div>
                </div>
                
                <div class="body mycred-ui-accordion-body" style="display: none;">
                    
                    <div class="row mb-4">
                        <h3 class="col-12 mb-3"><?php esc_html_e( 'Dashboard Settings', 'mycred' ); ?></h3>
                        
                        <div class="col-lg-4 col-md-4 col-sm-12">
                            <div class="form-group mb-3">
                                <?php  
                                mycred_create_toggle_field( 
                                    array(
                                        'id'    => 'myCRED-General-dashboard-enable',
                                        'name'  => 'mycred_pref_core[dashboard][dashboard_enable]',
                                        'label' => __( 'Enable Dashboard', 'mycred' ),
                                        'after' => true
                                    ), 
                                    ! empty ( $settings['dashboard_enable'] ) ? $settings['dashboard_enable'] : 0,
                                    ! empty ( $settings['dashboard_enable'] ) ? $settings['dashboard_enable'] : 0
                                );
                                ?>
                            </div>
                        </div>

                        <div class="col-lg-4 col-md-4 col-sm-12">
                            <div class="form-group mb-3">
                                <?php  
                                mycred_create_toggle_field( 
                                    array(
                                        'id'    => 'myCRED-General-user-filter',
                                        'name'  => 'mycred_pref_core[dashboard][enable_user_filter]',
                                        'label' => __( 'Enable User Filter', 'mycred' ), 
                                        'after' => true
                                    ), 
                                    ! empty ( $settings['enable_user_filter'] ) ? $settings['enable_user_filter'] : 0,
                                    ! empty ( $settings['enable_user_filter'] ) ? $settings['enable_user_filter'] : 0
                                );
                                ?>
                                <p><i><?php esc_html_e( 'When enabled, allows the admin to filter dashboard data by specific users.', 'mycred' ); ?></i></p>
                            </div>
                        </div>
                        
                        <div class="col-lg-4 col-md-4 col-sm-12">
                            <div class="form-group mb-3">
                                <label for="myCRED-Dashboard-default-point"><?php esc_html_e( 'Select Default Point Type', 'mycred' ); ?></label>
                                <?php 
                                mycred_create_select_field( 
                                    $available_point_types, 
                                    ! empty ( $settings['dashboard_default_point'] ) ? $settings['dashboard_default_point'] : 'mycred_default',
                                    array( 
                                        'id'       => 'myCRED-Dashboard-default-point',
                                        'class'    => 'mycred-select2',
                                        'name'     => 'mycred_pref_core[dashboard][dashboard_default_point]', 
                                        'multiple' => false 
                                    )
                                );
                                ?>
                            </div>
                        </div>
                        
                    </div>
                    
                </div>
                
            </div>
            
            <?php
        }
        
    }
    
    myCRED_Dashboard::instance();
    
endif;
