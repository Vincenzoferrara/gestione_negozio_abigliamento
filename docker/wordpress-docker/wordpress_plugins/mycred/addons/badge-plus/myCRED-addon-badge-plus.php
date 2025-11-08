<?php
/**
 * Addon: Badge Plus
 * Version: 1.0
 */

if ( ! defined( 'ABSPATH' ) ) exit;

if ( ! defined( 'myCRED_BADGE_PLUS_VERSION' ) )
    define( 'myCRED_BADGE_PLUS_VERSION', '1.0.0' );
if ( ! defined( 'MYCRED_BADGE_PLUS_SLUG' ) )
    define( 'MYCRED_BADGE_PLUS_SLUG', 'mycred-badge-plus' );
if ( ! defined( 'MYCRED_BADGE_PLUS' ) )
    define( 'MYCRED_BADGE_PLUS', __FILE__ );
if ( ! defined( 'MYCRED_BADGE_PLUS_DIR' ) )
    define( 'MYCRED_BADGE_PLUS_DIR', plugin_dir_path( MYCRED_BADGE_PLUS ) );
if ( ! defined( 'MYCRED_BADGE_PLUS_INCLUDES_DIR' ) )
    define( 'MYCRED_BADGE_PLUS_INCLUDES_DIR', MYCRED_BADGE_PLUS_DIR . 'includes/' );
// Badge Plus Requirements   
if ( ! defined( 'MYCRED_BADGE_PLUS_REQUIREMENTS_DIR' ) )
    define( 'MYCRED_BADGE_PLUS_REQUIREMENTS_DIR', MYCRED_BADGE_PLUS_INCLUDES_DIR . 'requirements/' );
// Badge Plus Blocks
if ( ! defined( 'MYCRED_BADGE_PLUS_BLOCKS_DIR' ) )
    define( 'MYCRED_BADGE_PLUS_BLOCKS_DIR', MYCRED_BADGE_PLUS_INCLUDES_DIR . 'blocks/' );
// Badge Plus Key
if ( ! defined( 'MYCRED_BADGE_PLUS_KEY' ) )
    define( 'MYCRED_BADGE_PLUS_KEY', 'mycred_badge_plus' );
// Badge Plus Type
if ( ! defined( 'MYCRED_BADGE_PLUS_TYPE' ) )
    define( 'MYCRED_BADGE_PLUS_TYPE', 'mycred_badge_plus_type' );

require_once MYCRED_BADGE_PLUS_INCLUDES_DIR . 'class-init.php';

myCred_Badge_Plus_Init::get_instance();