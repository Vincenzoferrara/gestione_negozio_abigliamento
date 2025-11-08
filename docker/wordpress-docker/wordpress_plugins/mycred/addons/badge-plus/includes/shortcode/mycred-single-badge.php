<?php
if ( ! defined( 'ABSPATH' ) ) exit;

if (! function_exists('mycred_render_single_badge_plus') ) :
    function mycred_render_single_badge_plus( $atts, $content = '' ) {

       $atts = shortcode_atts( array(
			'badge_id'      => 0,
			'title'         => 1,
			'image'         => 1,
			'image_size'    => 80,
			'title_link'    => 1,
			'excerpt'       => 0,
			'requirements'  => 0,
			'earners'       => 0,
			'earners_limit' => 10
		), $atts, MYCRED_SLUG . 'badge_plus' );

        if ( is_user_logged_in() && ! empty( $atts['badge_id'] ) ) {
            
            $badge_id = absint( $atts['badge_id'] );
        	$user_id = get_current_user_id();
			$badge = mycred_badge_plus_object( $badge_id );

	        if ( ! empty( $badge->post_id ) ) {

	        	$content = $badge->display_badge( $atts, $user_id );
	        }

        }
        else {
			return $content;
        
		}

        return apply_filters( 'mycred_single_badge_plus', $content );

    }
endif;
