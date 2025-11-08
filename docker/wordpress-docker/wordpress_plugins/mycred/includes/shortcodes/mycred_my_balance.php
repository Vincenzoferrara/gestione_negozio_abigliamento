<?php
if ( ! defined( 'myCRED_VERSION' ) ) exit;

/**
 * myCRED Shortcode: my_balance
 * Returns the current users balance.
 * @see http://codex.mycred.me/shortcodes/mycred_my_balance/
 * @since 1.0.9
 * @version 1.4
 */
if ( ! function_exists( 'mycred_render_shortcode_my_balance' ) ) :
	function mycred_render_shortcode_my_balance( $atts, $content = '' ) {

		// Define allowed elements
		$allowed_elements = array( 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'div', 'span', 'p' );

		// Extract attributes with defaults
		$atts = shortcode_atts( array(
			'user_id'   	=> 'current',
			'title'      	=> '',
			'title_el'   	=> 'h1',
			'balance_el' 	=> 'div',
			'wrapper'    	=> 1,
			'formatted'  	=> 1,
			'type'       	=> MYCRED_DEFAULT_TYPE_KEY,
			'image'			=> 0
		), $atts, MYCRED_SLUG . '_my_balance' );

		$mycred = mycred( $atts['type'] );

		$output = '';

		// Not logged in
		if ( ! is_user_logged_in() && $atts['user_id'] == 'current' )
			return esc_html( $content );

		// Get user ID
		$user_id = mycred_get_user_id( $atts['user_id'] );

		// Make sure we have a valid point type
		if ( ! mycred_point_type_exists( $atts['type'] ) )
			$atts['type'] = MYCRED_DEFAULT_TYPE_KEY;

		// Get the user's myCRED account object
		$account = mycred_get_account( $user_id );
		if ( $account === false ) return;

		// Check for exclusion
		if ( empty( $account->balance ) || ! array_key_exists( $atts['type'], $account->balance ) || $account->balance[ $atts['type'] ] === false ) return;

		$balance = $account->balance[ $atts['type'] ];

		// Secure and validate element tags
		$title_el = in_array( strtolower( $atts['title_el'] ), $allowed_elements ) ? $atts['title_el'] : 'h1';
		$balance_el = in_array( strtolower( $atts['balance_el'] ), $allowed_elements ) ? $atts['balance_el'] : 'div';

		// Sanitize text input
		$title = sanitize_text_field( $atts['title'] );

		if ( $atts['wrapper'] )
			$output .= '<div class="mycred-my-balance-wrapper">';

		// Title
		if ( ! empty( $title ) ) {
			$output .= '<' . esc_html( $title_el ) . '>' . esc_html( $title ) . '</' . esc_html( $title_el ) . '>';
		}

		// Balance
		$output .= '<' . esc_html( $balance_el ) . '>';

		// Image
		if ( $atts['image'] && isset( $mycred->image_url ) ) {
			$output .= '<img src="' . esc_url( $mycred->image_url ) . '" class="mycred-my-balance-image-' . esc_attr( $atts['type'] ) . '" width="20px" style="margin-right: 5px;" />';
		}

		// Balance output
		$output .= $atts['formatted'] ? esc_html( $balance->point_type->format( $balance->current ) ) : esc_html( $balance->point_type->number( $balance->current ) );

		$output .= '</' . esc_html( $balance_el ) . '>';

		if ( $atts['wrapper'] )
			$output .= '</div>';

		return $output;
	}
endif;

add_shortcode( MYCRED_SLUG . '_my_balance', 'mycred_render_shortcode_my_balance' );
