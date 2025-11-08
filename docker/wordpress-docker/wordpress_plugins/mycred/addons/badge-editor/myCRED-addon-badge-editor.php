<?php
/**
 * Addon: Badge Editor
 * Version: 1.0
 */

if( ! class_exists( 'myCred_Badge_Editor_Core' ) ) :

    /**
     * myCred_Badge_Editor_Core
     */
    class myCred_Badge_Editor_Core {
        
        /**
         * Hold the singleton object
         */
        private static $_instance;
        
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

            $this->define_constants();

            add_action( 'init', array( $this, 'init_badge_editor' ) );
        
        }

        /**
         * Define
         * @since 1.0
         * @version 1.0
         */
        private function define( $name, $value ) {
            if ( ! defined( $name ) )
                define( $name, $value );
        }

        /**
         * Define Constants
         * First, we start with defining all requires constants if they are not defined already.
         * @since 1.0
         * @version 1.0
         */
        private function define_constants() {

            $this->define( 'MYCRED_BADGE_EDITOR_THIS',         __FILE__ );
            $this->define( 'MYCRED_BADGE_EDITOR_VERSION',      '1.0' );
            $this->define( 'MYCRED_BADGE_EDITOR_ROOT_DIR',     myCRED_ADDONS_DIR . 'badge-editor/' );
            $this->define( 'MYCRED_BADGE_EDITOR_INCLUDES_DIR', MYCRED_BADGE_EDITOR_ROOT_DIR . 'includes/' );

        }
        
        /**
         * init_badge_editor
         *
         * @return void
         */
        public function init_badge_editor() {
            
            require_once MYCRED_BADGE_EDITOR_INCLUDES_DIR . 'class-mycred-badge-editor.php';
        
        }

    }
endif;

myCred_Badge_Editor_Core::get_instance();