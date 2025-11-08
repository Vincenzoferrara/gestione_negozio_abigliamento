<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * myCRED Shortcode: mycred_rank
 * Returns a given rank
 *
 * @see http://codex.mycred.me/shortcodes/mycred_rank/
 * @since 2.5
 * @version 1.0
 */
if ( ! function_exists( 'mycred_render_rank' ) ) :
	function mycred_render_rank( $atts, $content = '' ) {

		$atts = shortcode_atts(
			array(
				'rank_id'       => 0,
				'title'         => 1,
				'image'         => 1,
				'image_size'    => 80,
				'title_link'    => 1,
				'excerpt'       => 0,
				'requirements'  => 0,
				'earners'       => 0,
				'earners_limit' => 10,
			),
			$atts,
			MYCRED_SLUG . '_rank_plus'
		);

		if ( ! empty( $atts['rank_id'] ) ) {

			$rank_id = absint( $atts['rank_id'] );

			$rank = mycred_rank( $rank_id );

			$user_id = 0;

			if ( is_user_logged_in() ) {
				$user_id = get_current_user_id();
			}

			if ( ! empty( $rank->rank_id ) ) {

				$content = $rank->display_rank( $atts, $user_id );

			}
		}

		return apply_filters( 'mycred_rank', $content );
	}
endif;

/**
 * myCRED Shortcode: mycred_ranks
 * Returns the given type ranks.
 *
 * @see http://codex.mycred.me/shortcodes/mycred_ranks/
 * @since 2.5
 * @version 1.0
 */
if ( ! function_exists( 'mycred_render_ranks' ) ) :
	function mycred_render_ranks( $atts, $content = '' ) {

		$atts = shortcode_atts(
			array(
				'type_id'       => 0,
				'title'         => 1,
				'image'         => 1,
				'image_size'    => 80,
				'title_link'    => 1,
				'excerpt'       => 0,
				'requirements'  => 0,
				'earners'       => 0,
				'earners_limit' => 10,
				'display'       => 'horizontal', // horizontal, vertical
			),
			$atts,
			MYCRED_SLUG . '_ranks_plus'
		);

		if ( ! empty( $atts['type_id'] ) ) {

			$type_id = absint( $atts['type_id'] );

			$user_id = 0;

			if ( is_user_logged_in() ) {
				$user_id = get_current_user_id();
			}

			$ranks_cache = mycred_get_ranks_cache();

			if ( ! empty( $ranks_cache['sequence'][ $type_id ] ) && is_array( $ranks_cache['sequence'][ $type_id ] ) ) {

				$content = '<div class="mycred-ranks ' . esc_attr( $atts['display'] ) . '">';

				foreach ( $ranks_cache['sequence'][ $type_id ] as $rank_id ) {

					$rank = mycred_rank( $rank_id );

					if ( ! empty( $rank->rank_id ) ) {

						$content .= $rank->display_rank( $atts, $user_id );

					}
				}

				$content .= '</div>';

			}
		}

		return apply_filters( 'mycred_ranks', $content );
	}
endif;

/**
 * myCRED Shortcode: mycred_user_ranks
 * Returns all ranks who have the given user.
 *
 * @see http://codex.mycred.me/shortcodes/mycred_user_ranks/
 * @since 2.5
 * @version 1.0
 */
if ( ! function_exists( 'mycred_render_user_ranks' ) ) :
	function mycred_render_user_ranks( $atts, $content = 'You must be logged in to view your ranks.' ) {

		$atts = shortcode_atts(
			array(
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
				'display'       => 'horizontal', // horizontal, vertical, inline
			),
			$atts,
			MYCRED_SLUG . '_user_ranks'
		);

		$user_id = 0;

		if ( ! empty( $atts['user_id'] ) ) {

			if ( $atts['user_id'] == 'current' && is_user_logged_in() ) {

				$user_id = get_current_user_id();

			} else {

				$user_id = absint( $atts['user_id'] );

			}
		}

		unset( $atts['user_id'] );

		$type_id = '';

		if ( ! empty( $atts['type_id'] ) ) {
			$type_id = absint( $atts['type_id'] );
		}

		if ( ! empty( $user_id ) ) {

			if ( ! empty( $atts['display'] ) && $atts['display'] == 'inline' ) {

				$atts['excerpt']      = 0;
				$atts['requirements'] = 0;
				$atts['earners']      = 0;

			}

			$content = '<div class="mycred-user-ranks ' . esc_attr( $atts['display'] ) . '">';

			if ( ! empty( $atts['type_id'] ) ) {

				$type_id = absint( $atts['type_id'] );

				$rank_id = mycred_get_users_rank_by_type( $user_id, $type_id );

				if ( ! empty( $rank_id ) ) {

					$rank = mycred_rank( $rank_id );

					if ( ! empty( $rank->rank_id ) ) {

						$content .= $rank->display_rank( $atts, $user_id );

					}
				}
			} else {

				$ranks_cache = mycred_get_ranks_cache();

				if ( ! empty( $ranks_cache['sequence'] ) && is_array( $ranks_cache['sequence'] ) ) {

					foreach ( $ranks_cache['sequence'] as $type_id => $ranks_ids ) {

						$rank_id = mycred_get_users_rank_by_type( $user_id, $type_id );

						if ( ! empty( $rank_id ) ) {

							$rank = mycred_rank( $rank_id );

							if ( ! empty( $rank->rank_id ) ) {

								$content .= $rank->display_rank( $atts, $user_id );

							}
						}
					}
				}
			}

			$content .= '</div>';

		}

		return apply_filters( 'mycred_user_ranks', $content );
	}
endif;
