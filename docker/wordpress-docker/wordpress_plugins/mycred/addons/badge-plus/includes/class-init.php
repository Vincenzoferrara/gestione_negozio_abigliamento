<?php
if ( ! defined( 'ABSPATH' ) ) exit;

if ( ! class_exists( 'myCred_Badge_Plus_Init' ) ):
class myCred_Badge_Plus_Init {

    protected static $_instance = NULL;

    public static $version = '1.0.0';

    /**
     * Setup Instance
     * @since 1.0.0
     * @version 1.0.0
     */
    public static function get_instance() {

        if( is_null( self::$_instance ) ) {

            self::$_instance = new self();

        }

        return self::$_instance;
    }

    /**
     * Constructor
     * @since 1.0.0
     * @version 1.0.0
     */
    public function __construct() {

        require_once MYCRED_BADGE_PLUS_INCLUDES_DIR     . 'badge-plus-functions.php';

        add_filter( 'mycred_load_modules', array( $this, 'mycred_load_badge_plus_addon' ), 100, 2  );

    }

    /**
     * Load Badge Module and files
     * @since 1.0.0
     * @version 1.0.0
     */
    public function mycred_load_badge_plus_addon( $modules, $point_types ) {

        if ( empty( $modules['solo']['badge-plus'] ) ) {

            require_once MYCRED_BADGE_PLUS_INCLUDES_DIR . 'badge-plus-module-class.php';

            $modules['solo']['badge-plus'] = new myCRED_Badge_Plus_Module();
            $modules['solo']['badge-plus']->load();

        }

        return $modules;
        
    }

} 
endif;
