<?php
/**
 * Addon: Birthday
 * Version: 1.0.0
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( ! class_exists( 'myCRED_Birthdays' ) ) :
	class myCRED_Birthdays {

		// Plugin Version
		public $version             = '1.0.0';

		// Instnace
		protected static $_instance = NULL;

		/**
		 * Setup Instance
		 * @since 1.0
		 * @version 1.0
		 */
		public static function instance() {
			if ( is_null( self::$_instance ) ) {
				self::$_instance = new self();
			}
			return self::$_instance;
		}

		/**
		 * Not allowed
		 * @since 1.0
		 * @version 1.0
		 */
		public function __clone() { _doing_it_wrong( __FUNCTION__, 'Cheatin&#8217; huh?', '1.0' ); }

		/**
		 * Not allowed
		 * @since 1.0
		 * @version 1.0
		 */
		public function __wakeup() { _doing_it_wrong( __FUNCTION__, 'Cheatin&#8217; huh?', '1.0' ); }

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
		 * Require File
		 * @since 1.0
		 * @version 1.0
		 */
		public function file( $required_file ) {
			if ( file_exists( $required_file ) )
				require_once $required_file;
		}

		/**
		 * Construct
		 * @since 1.0
		 * @version 1.0
		 */
		public function __construct() {

			$this->define_constants();

			add_action( 'um_registration_complete', [ $this, 'normalize_birth_date' ], 10, 3 );
			add_filter( 'mycred_setup_hooks',    array( $this, 'register_hook' ) );
			add_action( 'mycred_all_references', array( $this, 'add_badge_support' ) );
			add_action( 'mycred_load_hooks',     array( $this, 'load_hooks' ) );

		}

		public function normalize_birth_date( $user_id, $submitted_data, $form_data ) {

		    // Get the birthdate field key via a filter
		    $birth_date_key = apply_filters( 'mycred_um_birthdate_field_key', 'birth_date' );

		    if ( isset( $submitted_data[ $birth_date_key ] ) ) {
		        $raw_date = $submitted_data[ $birth_date_key ];
		        $raw_date = str_replace( '/', '-', $raw_date );
		        $timestamp = strtotime( $raw_date );

		        if ( $timestamp ) {
		            $normalized_date = date( 'Y-m-d', $timestamp );
		            update_user_meta( $user_id, $birth_date_key, $normalized_date );
		        }
		    }

		}


		/**
		 * Define Constants
		 * @since 1.0
		 * @version 1.0
		 */
		public function define_constants() {

			$this->define( 'MYCRED_BP_COMPLIMENTS_VER',  $this->version );
			$this->define( 'MYCRED_BP_COMPLIMENTS_SLUG', 'mycred-birthdays' );
			$this->define( 'MYCRED_DEFAULT_TYPE_KEY',    'mycred_default' );
			$this->define( 'MYCRED_BIRTHDAY', __FILE__ );
			$this->define( 'MYCRED_BIRTHDAY_ROOT_DIR', plugin_dir_path( MYCRED_BIRTHDAY ) );
			$this->define( 'MYCRED_BIRTHDAY_INCLUDES_DIR', MYCRED_BIRTHDAY_ROOT_DIR . 'includes/' );

		}

		/**
		 * Includes
		 * @since 1.0
		 * @version 1.0
		 */
		public function includes() { }

		/**
		 * Register Hook
		 * @since 1.0
		 * @version 1.0
		 */
		public function register_hook( $installed ) {

			$installed['birthday'] = array(
				'title'         => __( '%plural% for Birthdays', 'mycred' ),
				'description'   => __( 'Reward users with points on their birthday', 'mycred' ),
				'documentation' => 'https://codex.mycred.me/hooks/birthdays/',
				'callback'      => array( 'myCRED_Birthday_Hook' )
			);

			return $installed;

		}

		/**
		 * Load Hook
		 * @since 1.0
		 * @version 1.0
		 */
		public function load_hooks() { 

			$this->file( MYCRED_BIRTHDAY_INCLUDES_DIR . 'mycred-birthday-hook.php' );

		}

		/**
		 * Add Badge Support
		 * @since 1.0
		 * @version 1.0
		 */
		public function add_badge_support( $references ) {

			$references['birthday'] = __( 'Birthday', 'mycred' );

			return $references;

		}

	}
	return myCRED_Birthdays::instance();
endif;