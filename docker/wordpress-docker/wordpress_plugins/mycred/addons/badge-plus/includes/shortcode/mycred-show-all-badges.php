<?php
if ( ! defined( 'ABSPATH' ) ) exit;
/**
 * Shortcode: mycred_badge_plus
 * Allows you to show all published badges of the specific type
 * @see http://codex.mycred.me/shortcodes/mycred_show_all_badge_plus/
 * @since 1.0.0
 * @version 1.0.0
 */
if ( ! function_exists( 'mycred_render_all_badge_plus' ) ) :
    function mycred_render_all_badge_plus( $atts, $content = '' ) {
        
        $atts = shortcode_atts( array(
			'type_id'       => 0,
			'title'         => 1,
			'image'         => 1,
			'image_size'    => 80,
			'title_link'    => 1,
			'excerpt'       => 0,
			'requirements'  => 0,
			'earners'       => 0,
			'earners_limit' => 10,
			'display'       => 'horizontal'//horizontal, vertical
		), $atts, MYCRED_SLUG . '_show_all_badge_plus' );

		if ( ! empty( $atts['type_id'] ) ) {

			$type_id = absint( $atts['type_id'] );

			if ( is_user_logged_in() ) $user_id = get_current_user_id();

			$content = '<div class="mycred-badges '. esc_attr( $atts['display'] ) .'">';
			$all_badges = mycred_get_badge_plus_ids();

			if ( ! empty( $all_badges ) ) {
	            foreach ( $all_badges as $key => $values ) {

	                $badge = mycred_badge_plus_object( $values->ID );
	             	
	                if( $badge->type->term_id == $atts['type_id'] ) {
		                
		                if ( ! empty( $badge->post_id ) ) {

				        	$content .= $badge->display_badge( $atts, $user_id );
				        }
				    }

	            }
	            $content .= '</div>';

	        }

		}

        return apply_filters( 'mycred_badge_plus', $content );

    }
endif;