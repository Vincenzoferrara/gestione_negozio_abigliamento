<?php

if( ! class_exists( 'myCred_Badge_Editor' ) ) :
    
    /**
     * myCred_Badge_Editor
     */
    class myCred_Badge_Editor {
        
        /**
         * _instance
         * 
         * @var mixed
         */
        private static $_instance;
        
        /**
         * assets
         *
         * @var mixed
         */
        private $assets;
        
        /**
         * get_instance
         *
         * @return void
         */
        public static function get_instance() {
            if ( self::$_instance == null )
                self::$_instance = new self();

            return self::$_instance;
        }
        
        /**
         * __construct
         *
         * @return void
         */
        public function __construct() {
   
            if( isset( $_GET['page'] ) && $_GET['page'] == 'mycred-badge-editor' ) {
                $this->add_actions();
                set_user_setting('mfold', 'f');
            } else {
                set_user_setting('mfold', '');
            }


            add_action( 'admin_menu', array( $this, 'add_submenu' ) );
            $this->assets = plugins_url( 'assets/images/', __DIR__ );

            add_action( 'wp_ajax_nopriv_mbe-subscribe', array( $this, 'subscribe' ) );
            add_action( 'wp_ajax_mbe-subscribe', array( $this, 'subscribe' ) );

        }
        
        /**
         * add_actions
         *
         * @return void
         */
        public function add_actions() {
            add_action( 'admin_enqueue_scripts', array( $this, 'admin_enqueue_scripts' ) );
            add_filter('script_loader_tag', array( $this, 'moduleTypeScripts' ), 10, 3);
            add_filter('style_loader_tag', array( $this, 'StylesLoaderTag' ), 10, 3);
        }
        
        /**
         * admin_enqueue_scripts
         *
         * @return void
         */
        public function admin_enqueue_scripts() {

            wp_register_script( 'mycred-badge-editor-init',  plugin_dir_url( __DIR__ ) . "assets/build/static/js/main.7d80124b.js", ['wp-element'], MYCRED_BADGE_EDITOR_VERSION, true );
            wp_enqueue_style( 'mycred-badge-editor-style-init', plugin_dir_url( __DIR__ ) . "assets/build/static/css/main.0a6594fe.css" );

            $opt_in = 0;

            global $myc_fs;

            if ( ! empty( $myc_fs ) && ! $myc_fs->is_anonymous() ) $opt_in = 1;

            if ( $opt_in == 0 ) {

                $has_manual_subscribe = get_option( 'mycred_mbe_subscribe' );

                if ( ! empty( $has_manual_subscribe ) && sanitize_email( $has_manual_subscribe ) ) $opt_in = 1;

            }

            $mbe_data = array(
                'is_mycred_opt_in' => $opt_in,
                'nonce' => wp_create_nonce( 'mbe-security-token' )
            );

            wp_localize_script( 'mycred-badge-editor-init', 'mbe_data', $mbe_data );

            wp_enqueue_script( 'mycred-badge-editor-init' );

        }
        
        /**
         * moduleTypeScripts
         *
         * @param  mixed $tag
         * @param  mixed $handle
         * @param  mixed $source
         * @return void
         */
        public function moduleTypeScripts( $tag, $handle, $source ) {
            if( ! is_admin() )
                return $tag;

            if( $handle == 'mycred-badge-editor-init' ) {
                $tag = '<script crossorigin src="'. $source .'"></script>';
            }
            return $tag;
        }
        
        /**
         * StylesLoaderTag
         *
         * @param  mixed $tag
         * @param  mixed $handle
         * @param  mixed $href
         * @return void
         */
        public function StylesLoaderTag( $tag,  $handle,  $href ) {
            if( $handle != 'buttons' ) {
                return $tag;
            }
        }
        
        /**
         * add_submenu
         *
         * @return void
         */
        public function add_submenu() {
            global $mycred;
            mycred_add_main_submenu(
                __( 'Badge Editor', 'mycred' ),
                __( 'Badge Editor', 'mycred' ),
                $mycred->get_point_editor_capability(),
                'mycred-badge-editor',
                array( $this, 'builder' )
            );
        }
        
        /**
         * builder
         *
         * @return void
         */
        public function builder() {

            $content = '<div id="root"></div>';
            echo wp_kses_post( $content );
            
        }

        public function subscribe() {

            $result = array( 'result' => 'error', 'msg' => __( 'Something went wrong try later.', 'mycred' ) );

            if ( empty( $_POST['email'] ) || empty( $_POST['nonce'] ) || ! wp_verify_nonce( $_POST['nonce'], 'mbe-security-token' ) ) 
                wp_send_json( array( 'result' => 'error', 'msg' => __( 'Something went wrong try later.', 'mycred' ) ) );

            $email = sanitize_email( wp_unslash( $_POST['email'] ) );

            $url = "https://wpexperts.us16.list-manage.com/subscribe/post-json?u=f3cb0c3cfd8f128bd28d6d006&id=6401675bc7&f_id=007797e1f0&EMAIL=$email";

            $args = array(
                'headers' => array(
                    'Accept' => 'application/json',
                )
            );

            $apiResponse = wp_remote_get( $url, $args );

            if ( ! is_wp_error( $apiResponse ) ) {
                
                $response_body = json_decode( wp_remote_retrieve_body( $apiResponse ) );

                if ( ! empty( $response_body->result ) && $response_body->result == 'success' ) {

                    $result = $response_body;

                    update_option( 'mycred_mbe_subscribe', $email );
                    
                }
                else {

                    if ( ! empty( $response_body->result ) ) $result = $response_body;
                
                }
                
            }

            wp_send_json( $result );

        }

    }

endif;

myCred_Badge_Editor::get_instance();