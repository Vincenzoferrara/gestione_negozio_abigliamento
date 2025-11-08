<?php

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( ! defined( 'MYCRED_RANK_PLUS_VERSION' ) ) {
	define( 'MYCRED_RANK_PLUS_VERSION', '1.0.2' );
}

if ( ! defined( 'MYCRED_RANK_PLUS_THIS' ) ) {
	define( 'MYCRED_RANK_PLUS_THIS', __FILE__ );
}

if ( ! defined( 'MYCRED_RANK_PLUS_DIR' ) ) {
	define( 'MYCRED_RANK_PLUS_DIR', plugin_dir_path( MYCRED_RANK_PLUS_THIS ) );
}

if ( ! defined( 'MYCRED_RANK_PLUS_INCLUDES_DIR' ) ) {
	define( 'MYCRED_RANK_PLUS_INCLUDES_DIR', MYCRED_RANK_PLUS_DIR . 'includes/' );
}

if ( ! defined( 'MYCRED_RANK_PLUS_REQUIREMENTS_DIR' ) ) {
	define( 'MYCRED_RANK_PLUS_REQUIREMENTS_DIR', MYCRED_RANK_PLUS_INCLUDES_DIR . 'requirements/' );
}

// Rank key
if ( ! defined( 'MYCRED_RANK_PLUS_KEY' ) ) {
	define( 'MYCRED_RANK_PLUS_KEY', 'mycred_rank_plus' );
}

// Rank Type key
if ( ! defined( 'MYCRED_RANK_TYPE_KEY' ) ) {
	define( 'MYCRED_RANK_TYPE_KEY', 'mycred_rank_types' );
}

require_once MYCRED_RANK_PLUS_INCLUDES_DIR . 'mycred-rank-plus-functions.php';

/**
 * Load Ranks Plus Module
 *
 * @since 2.5
 * @version 1.0
 */
if ( ! function_exists( 'mycred_load_ranks_plus_addon' ) ) :
	function mycred_load_ranks_plus_addon( $modules, $point_types ) {

		if ( version_compare( myCRED_VERSION, 2.5, '>=' ) ) {

			require_once MYCRED_RANK_PLUS_INCLUDES_DIR . 'mycred-rank-plus-module.php';

			$modules['solo']['rank-plus'] = new myCRED_Ranks_Plus_Module();
			$modules['solo']['rank-plus']->load();

		} else {

			add_action( 'admin_notices', 'mycred_ranks_plus_addon_notice' );

		}

		return $modules;
	}
endif;
add_filter( 'mycred_load_modules', 'mycred_load_ranks_plus_addon', 80, 2 );

if ( ! function_exists( 'mycred_ranks_plus_addon_notice' ) ) :
	function mycred_ranks_plus_addon_notice() {

		echo '<div class="notice notice-error is-dismissible"><p>myCred Rank Plus requires myCred v2.5 or a greater version.</p></div>';
	}
endif;

register_activation_hook( MYCRED_RANK_PLUS_THIS, 'mycred_rank_plus_activate' );

if ( ! function_exists( 'mycred_rank_plus_activate' ) ) :
	function mycred_rank_plus_activate() {

		mycred_rank_register_post();
		mycred_rank_register_post_type();

		flush_rewrite_rules();
		
	}
endif;
