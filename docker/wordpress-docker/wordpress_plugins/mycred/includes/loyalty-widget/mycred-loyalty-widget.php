<?php
if ( ! class_exists( 'myCRED_Loyalty_Widget_Page' ) ) :
    class myCRED_Loyalty_Widget_Page {
        
        private static $_instance = null;
        
        public static function instance() {
            if ( is_null( self::$_instance ) ) {
                self::$_instance = new self();
            }
            return self::$_instance;
        }
        
        public function __construct() {
            add_action( 'admin_init', array( $this, 'upload_default_media' ) );
            add_action( 'init', array( $this, 'migrate_program_title_defaults' ) );
            add_action( 'admin_menu', array( $this, 'add_menu_page' ) );
            add_action( 'admin_enqueue_scripts', array( $this, 'enqueue_scripts' ) );
            
            // Include API class
            require_once plugin_dir_path( __FILE__ ) . 'api/class-mycred-loyalty-widget-api.php';
            require_once plugin_dir_path( __FILE__ ) . 'class-mycred-loyalty-widget-frontend.php';
        }

        public function migrate_program_title_defaults() {
            $flag = 'mycred_loyalty_widget_program_title_v2_migrated';
            if ( get_option( $flag ) ) {
                return;
            }

            $settings = get_option( 'mycred_loyalty_widget_settings', array() );
            if ( is_array( $settings ) && isset( $settings['design'] ) && is_array( $settings['design'] ) ) {
                // Only update the exact legacy default string, so custom branding is not overwritten.
                if ( isset( $settings['design']['programTitle'] ) && is_string( $settings['design']['programTitle'] ) && 'myCred Rewards' === $settings['design']['programTitle'] ) {
                    $settings['design']['programTitle'] = 'Rewards Hub';
                    update_option( 'mycred_loyalty_widget_settings', $settings );
                }
            }

            update_option( $flag, time() );
        }

        public function upload_default_media() {
            if ( get_option( 'mycred_loyalty_widget_defaults_uploaded_v2' ) ) {
                return;
            }
            
            update_option( 'mycred_loyalty_widget_defaults_uploaded_v2', time() );
            
            if ( ! function_exists( 'wp_generate_attachment_metadata' ) ) {
                require_once( ABSPATH . 'wp-admin/includes/image.php' );
                require_once( ABSPATH . 'wp-admin/includes/file.php' );
                require_once( ABSPATH . 'wp-admin/includes/media.php' );
            }

            $images_to_upload = array(
                'heroImageUrl' => array(
                    'file'  => plugin_dir_path( __FILE__ ) . 'src/assets/widget-icon/default-logo1.svg',
                    'title' => 'myCred Loyalty Widget Hero Brand Image',
                ),
                'headerImageUrl' => array(
                    'file'  => plugin_dir_path( __FILE__ ) . 'src/assets/widget-icon/mycred_widget_header.png',
                    'title' => 'myCred Loyalty Widget Header Image',
                ),
                'logoUrl' => array(
                    'file'  => plugin_dir_path( __FILE__ ) . 'src/assets/widget-icon/widget-logo.png',
                    'title' => 'myCred Loyalty Widget Logo',
                ),
            );

            $settings = get_option( 'mycred_loyalty_widget_settings', array() );
            $updated = false;

            foreach ( $images_to_upload as $key => $data ) {
                if ( ! file_exists( $data['file'] ) ) continue;

                $query = new WP_Query( array(
                    'post_type'      => 'attachment',
                    'post_status'    => 'inherit',
                    'title'          => $data['title'],
                    'posts_per_page' => 1,
                    'fields'         => 'ids',
                ) );

                $attachment_url = '';
                if ( $query->have_posts() ) {
                    $attachment_url = wp_get_attachment_url( $query->posts[0] );
                } else {
                    $upload_dir = wp_upload_dir();
                    $filename = basename( $data['file'] );
                    $upload_file = wp_unique_filename( $upload_dir['path'], $filename );
                    $new_file = $upload_dir['path'] . '/' . $upload_file;

                    if ( copy( $data['file'], $new_file ) ) {
                        $mime_type = wp_check_filetype( $new_file, null );
                        $type = ! empty( $mime_type['type'] ) ? $mime_type['type'] : 'image/svg+xml';
                        $attachment = array(
                            'post_mime_type' => $type,
                            'post_title'     => $data['title'],
                            'post_content'   => '',
                            'post_status'    => 'inherit'
                        );

                        $attach_id = wp_insert_attachment( $attachment, $new_file );
                        if ( ! is_wp_error( $attach_id ) ) {
                            $attach_data = wp_generate_attachment_metadata( $attach_id, $new_file );
                            wp_update_attachment_metadata( $attach_id, $attach_data );
                            $attachment_url = wp_get_attachment_url( $attach_id );
                        }
                    }
                }

                if ( ! empty( $attachment_url ) ) {
                    if ( ! isset( $settings['design'] ) ) {
                        $settings['design'] = array();
                    }
                    if ( empty( $settings['design'][ $key ] ) ) {
                        $settings['design'][ $key ] = $attachment_url;
                        $updated = true;
                    }
                }
            }

            if ( $updated ) {
                update_option( 'mycred_loyalty_widget_settings', $settings );
            }
        }

        public function add_menu_page() {
            mycred_add_main_submenu( 
                __( 'Loyalty Widget', 'mycred' ),
                __( 'Loyalty Widget', 'mycred' ),
                'manage_options', 
                'mycred-loyalty-widget',
                array( $this, 'render_page' )
            );
        }

        public function enqueue_scripts( $hook ) {
            if ( 'mycred_page_mycred-loyalty-widget' !== $hook ) {
                return;
            }

            $build_file = plugin_dir_path( __FILE__ ) . 'build/index.bundle.js';
            $build_url  = plugin_dir_url( __FILE__ ) . 'build/index.bundle.js';
            
            $is_toolkit_pro_active = false;
            $active_plugins = (array) get_option( 'active_plugins', array() );
            if ( in_array( 'mycred-toolkit-pro/mycred-toolkit-pro.php', $active_plugins, true ) ) {
                if( file_exists( WP_PLUGIN_DIR . '/mycred-toolkit-pro/includes/mycred-toolkit-plan-check.php' ) ) {
                    $is_toolkit_pro_active = true;    
                }
            }

            if ( file_exists( $build_file ) ) {
                $asset_file = include( plugin_dir_path( __FILE__ ) . 'build/index.bundle.asset.php' );
                
                wp_enqueue_script(
                    'mycred-loyalty-widget-script',
                    $build_url,
                    $asset_file['dependencies'],
                    $asset_file['version'],
                    true
                );

                $settings = get_option( 'mycred_loyalty_widget_settings', array() );

                // Get active myCred hooks
                $active_hooks = array();
                if ( function_exists( 'mycred_get_types' ) ) {
                    $types = mycred_get_types();
                    foreach ( $types as $type => $label ) {
                        $hook_prefs = get_option( 'mycred_pref_hooks' . ( $type !== 'mycred_default' ? '_' . $type : '' ) );
                        if ( ! empty( $hook_prefs['active'] ) ) {
                            // Instantiate hooks module to get details
                            $hooks_module = new myCRED_Hooks_Module( $type );
                            $installed = $hooks_module->get();
                            $mycred = mycred( $type );
                            
                            foreach ( $hook_prefs['active'] as $hook_id ) {
                                if ( isset( $installed[ $hook_id ] ) ) {
                                    $raw_title = $installed[ $hook_id ]['title'];
                                    $raw_desc  = $installed[ $hook_id ]['description'];

                                    $amount = isset( $hook_prefs['hook_prefs'][ $hook_id ] ) ? $this->get_hook_amount( $hook_prefs['hook_prefs'][ $hook_id ] ) : 0;

                                    $active_hooks[] = array(
                                        'id'               => $hook_id,
                                        'point_type'       => $type,
                                        'type_label'       => $label,
                                        'category'         => $this->get_hook_category( $hook_id ),
                                        'title'            => $mycred->template_tags_general( $raw_title ),
                                        'description'      => $mycred->template_tags_general( $raw_desc ),
                                        'raw_title'        => $raw_title,
                                        'amount'           => $amount,
                                        'formatted_amount' => $mycred->format_creds( $amount ),
                                    );
                                }
                            }
                        }
                    }
                }

                // Get available pages for redirects
                $pages = get_pages( array(
                    'post_status' => 'publish',
                    'sort_column' => 'post_title',
                    'hierarchical' => 0
                ) );

                $available_pages = array();
                if ( ! empty( $pages ) ) {
                    foreach ( $pages as $page ) {
                        $available_pages[] = array(
                            'id'    => $page->ID,
                            'title' => $page->post_title,
                            'url'   => get_permalink( $page->ID )
                        );
                    }
                }


                if ( class_exists( 'myCRED_Loyalty_Widget_API' ) ) {
                    $defaults = myCRED_Loyalty_Widget_API::instance()->get_default_settings();
                    $settings = myCRED_Loyalty_Widget_API::merge_defaults( $settings, $defaults );
                }

                global $wp_roles;
                if ( ! isset( $wp_roles ) ) {
                    $wp_roles = new WP_Roles();
                }
                $available_roles = array();
                foreach ( $wp_roles->get_names() as $role_key => $role_name ) {
                    $available_roles[] = array(
                        'key'  => $role_key,
                        'name' => $role_name
                    );
                }

                wp_localize_script( 'mycred-loyalty-widget-script', 'mycredLoyaltyWidgetData', array(
                    'rest_url' => esc_url_raw( rest_url() ),
                    'nonce'    => wp_create_nonce( 'wp_rest' ),
                    'is_toolkit_pro_active' => $is_toolkit_pro_active,
                    'settings' => $settings,
                    'available_pages' => $available_pages,
                    'active_hooks' => $active_hooks,
                    'available_roles' => $available_roles,
                    'assets_url' => plugin_dir_url( __FILE__ ) . 'src/assets/widget-icon/'
                ) );
                
                wp_enqueue_style( 'wp-components' );
                wp_enqueue_media();
            }
        }

        private function get_hook_amount( $prefs ) {
            if ( ! is_array( $prefs ) ) {
                return is_numeric( $prefs ) ? $prefs : 0;
            }
            
            if ( isset( $prefs['creds'] ) && ! is_array( $prefs['creds'] ) ) {
                return $prefs['creds'];
            }
            if ( isset( $prefs['amount'] ) && ! is_array( $prefs['amount'] ) ) {
                return $prefs['amount'];
            }
            
            foreach ( $prefs as $key => $value ) {
                if ( is_array( $value ) ) {
                    if ( isset( $value['creds'] ) && ! is_array( $value['creds'] ) ) {
                        return $value['creds'];
                    }
                    if ( isset( $value['amount'] ) && ! is_array( $value['amount'] ) ) {
                        return $value['amount'];
                    }
                }
            }
            
            if ( isset( $prefs['creds'] ) && is_array( $prefs['creds'] ) ) {
                foreach ( $prefs['creds'] as $val ) {
                    if ( is_numeric( $val ) && $val > 0 ) return $val;
                }
            }

            return 0;
        }

        private function get_hook_category( $hook_id ) {
            $hook_id = strtolower( $hook_id );
            if ( strpos( $hook_id, 'woocommerce' ) !== false ) return 'woocommerce';
            if ( strpos( $hook_id, 'buddypress' ) !== false || strpos( $hook_id, 'bp_' ) === 0 ) return 'buddypress';
            if ( strpos( $hook_id, 'bbpress' ) !== false || strpos( $hook_id, 'forum' ) !== false ) return 'forum';
            return 'wordpress';
        }

        public function render_page() {
            echo '<div id="mycred-loyalty-widget" style="margin-left:-20px"></div>';
        }
        
    }
    
    myCRED_Loyalty_Widget_Page::instance();
    
endif;
