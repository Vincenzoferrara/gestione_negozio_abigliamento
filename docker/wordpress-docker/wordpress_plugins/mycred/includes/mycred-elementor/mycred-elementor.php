<?php

if ( ! defined('ABSPATH') ) {
    exit; // Exit if accessed directly.
}

/**
 * Main Elementor Test Extension Class
 *
 * The main class that initiates and runs the plugin.
 *
 * @since 1.0.0
 */
if( ! class_exists('MyCred_Elementor_Main') ):
    class MyCred_Elementor_Main {

        /**
         * Plugin Version
         *
         * @since 1.0.0
         *
         * @var string The plugin version.
         */
        const VERSION = '1.2.4';

        /**
         * Minimum Elementor Version
         *
         * @since 1.0.0
         *
         * @var string Minimum Elementor version required to run the plugin.
         */
        const MINIMUM_ELEMENTOR_VERSION = '2.0.0';

        /**
         * Minimum PHP Version
         *
         * @since 1.0.0
         *
         * @var string Minimum PHP version required to run the plugin.
         */
        const MINIMUM_PHP_VERSION = '7.0';

        /**
         * Instance
         *
         * @since 1.0.0
         *
         * @access private
         * @static
         *
         * @var Elementor_Test_Extension The single instance of the class.
         */
        private static $_instance = null;

        /**
         * Instance
         *
         * Ensures only one instance of the class is loaded or can be loaded.
         *
         * @since 1.0.0
         *
         * @access public
         * @static
         *
         * @return Elementor_Test_Extension An instance of the class.
         */
        public static function instance() {

            if (is_null(self::$_instance)) {
                self::$_instance = new self();
            }
            return self::$_instance;
        }

        /**
         * Define
         * @since 1.0
         * @version 1.0
         */
        private function define( $name, $value, $definable = true ) {
            if ( ! defined( $name ) )
                define( $name, $value );
        }

        /**
         * Constructor
         *
         * @since 1.0.0
         *
         * @access public
         */
        public function __construct() {

            $this->define_constants();

            add_action( 'plugins_loaded', [$this, 'init'] );

        }

        /**
         * Define Constants
         * @since 1.0
         * @version 1.0
         */
        public function define_constants() {

            $this->define( 'mycred_elementor_VERSION',  '1.2.4' );
            $this->define( 'mycred_elementor_SLUG', 'mycred-elementor' );
            $this->define( 'mycred_elementor', __FILE__ );

        }

        /**
         * Initialize the plugin
         *
         * Load the plugin only after Elementor (and other plugins) are loaded.
         * Checks for basic plugin requirements, if one check fail don't continue,
         * if all check have passed load the files required to run the plugin.
         *
         * Fired by `plugins_loaded` action hook.
         *
         * @since 1.0.0
         *
         * @access public
         */
        public function init() {


    // Check if Elementor installed and activated
            if (!did_action('elementor/loaded')) {
                add_action('admin_notices', [$this, 'admin_notice_missing_main_plugin']);
                return;
            }

            if (!class_exists('myCRED_Core')) {
                add_action('admin_notices', [$this, 'admin_notice_mycred_missing_plugin']);
                return;
            }
    // Check for required Elementor version
            if (!version_compare(ELEMENTOR_VERSION, self::MINIMUM_ELEMENTOR_VERSION, '>=')) {
                add_action('admin_notices', [$this, 'admin_notice_minimum_elementor_version']);
                return;
            }

    // Check for required PHP version
            if (version_compare(PHP_VERSION, self::MINIMUM_PHP_VERSION, '<')) {
                add_action('admin_notices', [$this, 'admin_notice_minimum_php_version']);
                return;
            }

            $this->includes();

    // Add Plugin actions
            add_action('elementor/widgets/widgets_registered', [$this, 'init_widgets']);
        }

        public function includes() {
            require_once( __DIR__ . '/includes/mycred-elem-functions.php' );
        }

        /**
         * Admin notice
         *
         * Warning when the site doesn't have Elementor installed or activated.
         *
         * @since 1.0.0
         *
         * @access public
         */
        public function admin_notice_missing_main_plugin() {
            if (isset($_GET['activate']))
                unset($_GET['activate']);

            $message = sprintf(
                    /* translators: 1: Plugin name 2: Elementor */
                    esc_html__('"%1$s" requires "%2$s" to be installed and activated.', 'mycred'), '<strong>' . esc_html__('Elementor Test Extension', 'mycred') . '</strong>', '<strong>' . esc_html__('Elementor', 'mycred') . '</strong>'
            );

            printf('<div class="notice notice-warning is-dismissible"><p>%1$s</p></div>', $message);
            
          
        }

        /**
         * Admin notice
         *
         * Warning when the site doesn't have mycred installed or activated.
         *
         * @since 1.0.0
         *
         * @access public
         */
        public function admin_notice_mycred_missing_plugin() {

            if (isset($_GET['activate']))
                unset($_GET['activate']);

            $message = sprintf(
                    /* translators: 1: Plugin name 2: Elementor */
                    esc_html__('"%1$s" requires "%2$s" to be installed and activated.', 'mycred'), '<strong>' . esc_html__('myCred for Elementor', 'mycred') . '</strong>', '<strong>' . esc_html__('myCred', 'mycred') . '</strong>'
            );

            printf('<div class="notice notice-warning is-dismissible"><p>%1$s</p></div>', $message);
        }

        /**
         * Admin notice
         *
         * Warning when the site doesn't have a minimum required Elementor version.
         *
         * @since 1.0.0
         *
         * @access public
         */
        public function admin_notice_minimum_elementor_version() {

            if (isset($_GET['activate']))
                unset($_GET['activate']);

            $message = sprintf(
                    /* translators: 1: Plugin name 2: Elementor 3: Required Elementor version */
                    esc_html__('"%1$s" requires "%2$s" version %3$s or greater.', 'mycred'), '<strong>' . esc_html__('Elementor Test Extension', 'mycred') . '</strong>', '<strong>' . esc_html__('Elementor', 'mycred') . '</strong>', self::MINIMUM_ELEMENTOR_VERSION
            );

            printf('<div class="notice notice-warning is-dismissible"><p>%1$s</p></div>', $message);
        }

        /**
         * Admin notice
         *
         * Warning when the site doesn't have a minimum required PHP version.
         *
         * @since 1.0.0
         *
         * @access public
         */
        public function admin_notice_minimum_php_version() {

            if (isset($_GET['activate']))
                unset($_GET['activate']);

            $message = sprintf(
                    /* translators: 1: Plugin name 2: PHP 3: Required PHP version */
                    esc_html__('"%1$s" requires "%2$s" version %3$s or greater.', 'mycred'), '<strong>' . esc_html__('Elementor Test Extension', 'mycred') . '</strong>', '<strong>' . esc_html__('PHP', 'mycred') . '</strong>', self::MINIMUM_PHP_VERSION
            );

            printf('<div class="notice notice-warning is-dismissible"><p>%1$s</p></div>', $message);
        }

        /**
         * Init Widgets
         *
         * Include widgets files and register them
         *
         * @since 1.0.0
         *
         * @access public
         */
        public function init_widgets() {

            require_once( __DIR__ . "/includes/widgets/mycred-core.php" );
            $core_shortcodes = [
                'mycred_total_pts',
                'mycred_total_balance',
                'mycred_history',
                'mycred_total_since',
                'mycred_leaderboard',
                'mycred_best_user',
                'mycred_exchange',
                'mycred_link',
                'mycred_give',
                'mycred_affiliate_id',
                'mycred_affiliate_link',
                'mycred_hook_table',
                'mycred_my_balance',
                // 'mycred_send',
                'mycred_video',
                // 'mycred_hide_if',
                // 'mycred_show_if',
            ];

            $this->mycred_register_widget($core_shortcodes);

    // Badges
            if (class_exists('myCRED_Badge_Module')) {
                require_once( __DIR__ . "/includes/widgets/mycred-badges-addon.php" );
    //register widget
                $badge_shortcodes = [
                    'mycred_my_badges',
                    'mycred_badges',
                ];
                $this->mycred_register_widget($badge_shortcodes);
            }

    //Buy

            if (class_exists('myCRED_buyCRED_Module')) {
                require_once( __DIR__ . "/includes/widgets/mycred-buycred-addon.php" );
    //register widget
                $buy_shortcodes = [
                    'mycred_buy',
                    'mycred_buy_form',
                ];
                $this->mycred_register_widget($buy_shortcodes);
            }

    //Coupons
            if (class_exists('myCRED_Coupons_Module')) {
                require_once( __DIR__ . "/includes/widgets/mycred-coupons-addon.php" );
    //register widget
                $coupon_shortcodes = [
                    'mycred_load_coupon',
                ];
                $this->mycred_register_widget($coupon_shortcodes);
            }

    //Email
            if (class_exists('myCRED_Email_Notice_Module')) {
                require_once( __DIR__ . "/includes/widgets/mycred-emails-addon.php" );
    //register widget
                $email_shortcodes = [
                    'mycred_email_subscriptions',
                ];
                $this->mycred_register_widget($email_shortcodes);
            }

    //Ranks

            if (class_exists('myCRED_Ranks_Module')) {
                require_once( __DIR__ . "/includes/widgets/mycred-ranks-addon.php" );
    //register widget
                $rank_shortcodes = [
                    'mycred_my_rank',
                    'mycred_my_ranks',
                    'mycred_users_of_rank',
                    'mycred_users_of_all_ranks',
                    'mycred_list_ranks',
                ];
                $this->mycred_register_widget($rank_shortcodes);
            }

    //Sell Content
            /*if (class_exists('myCRED_Sell_Content_Module')) {
                require_once( __DIR__ . "/includes/widgets/mycred-sell-content-addon.php" );
    //register widget
                $sell_content_shortcodes = [
                    'mycred_content_buyer_count',
                    'mycred_content_sale_count',
                    'mycred_content_buyer_avatars',
                    'mycred_sales_history',
                    'mycred_sell_this',
                ];
                $this->mycred_register_widget($sell_content_shortcodes);
            }
    */
    //Transfer

            if (class_exists('myCRED_Transfer_Module')) {
                require_once( __DIR__ . "/includes/widgets/mycred-transfers-addon.php" );
    //register widget
                $transfer_shortcodes = [
                    'mycred_transfer',
                ];
                $this->mycred_register_widget($transfer_shortcodes);
            }
        }

        public function mycred_register_widget($build_mycred_widgets_filename) {
            foreach ($build_mycred_widgets_filename as $mycred_widget_filename) {
    // Include Widget files
                $class_name = str_replace('-', '_', $mycred_widget_filename);
                $class_name = __NAMESPACE__ . '\Widget_' . $class_name;
    // Register widget
                \Elementor\Plugin::instance()->widgets_manager->register_widget_type(new $class_name());
            }
        }
    }
endif;

function mycred_elementor_load() {
    include_once ABSPATH . 'wp-admin/includes/plugin.php';

    if ( ! is_plugin_active( 'mycred-for-elementor/mycred-elementor.php' ) && is_plugin_active( 'elementor/elementor.php' ) ) {
       return MyCred_Elementor_Main::instance();
    }
}
mycred_elementor_load();
