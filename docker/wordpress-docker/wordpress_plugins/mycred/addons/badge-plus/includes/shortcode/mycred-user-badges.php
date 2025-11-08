<?php
if ( ! defined( 'ABSPATH' ) ) exit;

/**
 * myCRED Shortcode: mycred_user_badge
 * Returns all badges who have the given user.
 * @see http://codex.mycred.me/shortcodes/mycred_user_badge_plus/
 * @since 1.0.0
 * @version 1.0.0
 */
if ( ! function_exists( 'mycred_render_user_badge' ) ) :
	function mycred_render_user_badge( $atts, $content = 'You must be logged in to view your badges.' ) {

		$atts = shortcode_atts( array(
			'user_id'       => 'current',
			'type_id'       => '',
			'title'         => 1,
			'image'         => 1,
			'image_size'    => 80,
			'title_link'    => 1,
			'excerpt'       => 0,
			'requirements'  => 0,
			'earners'       => 0,
			'earners_limit' => 10,
			'display'       => 'horizontal'//horizontal, vertical, inline
		), $atts, MYCRED_SLUG . '_user_badges' );

		$user_id = 0;

		if ( ! empty( $atts['user_id'] ) ) {
			
			if ( $atts['user_id'] == 'current' && is_user_logged_in() ) {
				
				$user_id = get_current_user_id();

			}
			else {

				$user_id = absint( $atts['user_id'] );

			}

		}

		unset( $atts['user_id'] );

		$type_id = '';
		$all_badges = mycred_get_badge_plus_ids();
		
		if ( ! empty( $atts['type_id'] ) ) $type_id = absint( $atts['type_id'] );

		if ( ! empty( $user_id ) ) {

			if ( ! empty( $atts['display'] ) && $atts['display'] == 'inline' ) {
				
				$atts['excerpt']      = 0;
				$atts['requirements'] = 0;
				$atts['earners']      = 0;

			}

			$content = '<div class="mycred-user-badges '. esc_attr( $atts['display'] ) .'">';

			if ( ! empty( $atts['type_id'] ) && ! empty( $all_badges ) ) {
				
				$type_id = absint( $atts['type_id'] );
				
				foreach ( $all_badges as $key => $values ) {

					$badge = mycred_badge_plus_object( $values->ID );
	             	
	                if( $badge->type->term_id == $type_id ) {
		                
		                if ( ! empty( $badge->post_id ) && $badge->user_has_badge( $user_id, $values->ID ) ) {

				        	$content .= $badge->display_badge( $atts, $user_id );
				        }
				    }

				}

			}
			else {

				if ( ! empty( $all_badges ) ) {
		            foreach ( $all_badges as $key => $values ) {

		                $badge = mycred_badge_plus_object( $values->ID );
			                
		                if ( ! empty( $badge->post_id ) && $badge->user_has_badge( $user_id, $values->ID ) ) {

				        	$content .= $badge->display_badge( $atts, $user_id );
				        }

		            }

		        }

			}
			
			$content .= '</div>'; 

		}

		return apply_filters( 'mycred_user_badges', $content );

	}
endif;