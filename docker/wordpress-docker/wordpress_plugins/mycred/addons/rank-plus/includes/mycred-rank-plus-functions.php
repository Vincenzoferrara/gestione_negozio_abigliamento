<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( ! function_exists( 'mycred_rank_register_post' ) ) :
	function mycred_rank_register_post() {

		$labels = array(
			'name'                  => __( 'Ranks', 'mycred' ),
			'singular_name'         => __( 'Rank', 'mycred' ),
			'add_new'               => __( 'Add New Rank', 'mycred' ),
			'add_new_item'          => __( 'Add New Rank', 'mycred' ),
			'edit_item'             => __( 'Edit Rank', 'mycred' ),
			'new_item'              => __( 'New Rank', 'mycred' ),
			'all_items'             => __( 'All Ranks', 'mycred' ),
			'view_item'             => __( 'View Rank', 'mycred' ),
			'search_items'          => __( 'Search Ranks', 'mycred' ),
			'featured_image'        => __( 'Rank Image', 'mycred' ),
			'set_featured_image'    => __( 'Set rank image', 'mycred' ),
			'remove_featured_image' => __( 'Remove rank image', 'mycred' ),
			'use_featured_image'    => __( 'Use as Image', 'mycred' ),
			'not_found'             => __( 'No ranks found', 'mycred' ),
			'not_found_in_trash'    => __( 'No ranks found in Trash', 'mycred' ),
			'parent_item_colon'     => '',
			'menu_name'             => __( 'Rank Plus', 'mycred' ),
		);

		// Support
		$supports = array( 'title', 'thumbnail', 'excerpt', 'editor', 'author', 'custom-fields' );

		// Custom Post Type Attributes
		$args = array(
			'labels'              => $labels,
			'supports'            => $supports,
			'hierarchical'        => false,
			'public'              => true,
			'publicly_queryable'  => true,
			'show_ui'             => true,
			'show_in_menu'        => true,
			'show_in_nav_menus'   => false,
			'show_in_admin_bar'   => false,
			'menu_position'       => 21,
			'can_export'          => true,
			'has_archive'         => true,
			'exclude_from_search' => true,
			'capability_type'     => 'post',
			'show_in_rest'        => true,
			'menu_icon'           => 'dashicons-shield-alt',
			'taxonomies'          => array( MYCRED_RANK_TYPE_KEY ),
			'rewrite'             => array(
				'slug'       => MYCRED_RANK_PLUS_KEY,
				'with_front' => true,
			),
		);

		register_post_type( MYCRED_RANK_PLUS_KEY, apply_filters( 'mycred_register_rank_plus', $args ) );
	}
endif;

if ( ! function_exists( 'mycred_rank_register_post_type' ) ) :
	function mycred_rank_register_post_type() {

		$labels = array(
			'name'         => __( 'Rank Types', 'mycred' ),
			'menu_name'    => __( 'Rank Types', 'mycred' ),
			'all_items'    => __( 'Rank Types', 'mycred' ),
			'add_new_item' => __( 'Add New Rank Type', 'mycred' ),
			'parent_item'  => __( 'Parent Rank Type', 'mycred' ),
		);

		$args = array(
			'labels'            => $labels,
			'show_ui'           => true,
			'show_in_menu'      => true,
			'show_admin_column' => false,
			'query_var'         => true,
			'rewrite'           => array(
				'slug' => MYCRED_RANK_PLUS_KEY,
			),
			'show_in_rest'      => true,
			'hierarchical'      => true,
		);

		register_taxonomy(
			MYCRED_RANK_TYPE_KEY,
			MYCRED_RANK_PLUS_KEY,
			$args
		);
	}
endif;

if ( ! function_exists( 'mycred_rank_requirement_html' ) ) :
	function mycred_rank_requirement_html( $data = array(), $sequence = 1, $echo = true ) {

		ob_start();

		$label             = ! empty( $data['label'] ) ? $data['label'] : '';
		$required          = ! empty( $data['required'] ) ? $data['required'] : 'required';
		$post_types        = ! empty( $data['post_types'] ) ? $data['post_types'] : '';
		$single_post       = ! empty( $data['single_post'] ) ? $data['single_post'] : '';
		$point_type        = ! empty( $data['point_type'] ) ? $data['point_type'] : MYCRED_DEFAULT_TYPE_KEY;
		$amount_by         = ! empty( $data['amount_by'] ) ? $data['amount_by'] : 'times';
		$limit_by          = ! empty( $data['limit_by'] ) ? $data['limit_by'] : 'day';
		$selected_refrence = ! empty( $data['reference'] ) ? $data['reference'] : 'registration';

		?>
		<li class="mycred-meta-repeater">
				<div class="mycred-meta-repeater-header">
					<div class="title">
						<span class="mycred-sortable-sequence"><?php echo empty( $sequence ) ? '{{sequence}}' : absint( $sequence ); ?> - </span>
						<span class="mrr-title"><?php echo esc_html( $label ); ?></span>
					</div>
					<div class="actions">
						<div class="mrr-requirement-delete-wrapper">
							<span class="dashicons dashicons-trash mrr-requirement-delete"></span>
						</div>
					</div>
			</div>
				<div class="mycred-meta-repeater-body">
				<div class="row">
					<div class="col-md-1 mycred-meta-lbl">
						<label for="cname">Label: </label>
					</div>
					<div class="col-md-9 flex-grow-1">
					<?php
						$atts = array(
							'class'       => 'mb-4 mrr-label',
							'placeholder' => 'Requirement label',
							'data-index'  => 'label',
						);

						if ( ! empty( $label ) ) {
							$atts['value'] = $label;
						}

						mycred_create_input_field( $atts );
						?>
					</div>
					<div class="col-md-2">
					<?php
						$is_required_options = array(
							'required' => 'Required',
							'optional' => 'Optional',
						);
						$is_required_atts    = array(
							'class'      => 'mycred-ui-form mb-4 mrr-is-required',
							'data-index' => 'required',
						);
						mycred_create_select_field( $is_required_options, $required, $is_required_atts );
						?>
					</div>
				</div>
				<div class="row mycred-meta-requirement-row">
					<div class="col-md-1 mycred-meta-lbl">
						<label for="cname">When: </label>
					</div>
					<div class="col-md-4 mb-4" data-column="refrence">
					<?php
						$reference_ids_atts = array(
							'class'      => 'form-control mycred-select2 mrr-refrence',
							'data-index' => 'reference',
							'style'      => 'width: 100%;',
						);

						$event_groups = apply_filters(
							'mycred_rank_requirement_event_groups',
							array(
								'refrences_group' => array( 'label' => 'Refrences' ),
								'other_group'     => array( 'label' => 'Other' ),
							)
						);

						$rank_events = mycred_get_rank_events();

					foreach ( $rank_events as $key => $event ) {

						$event_groups[ $event['group'] ]['options'][ $key ] = $event['title'];

					}
						mycred_create_select_field( $event_groups, $selected_refrence, $reference_ids_atts );
					?>
					</div>
					<div class="col-md-7 flex-grow-1 mycred-meta-req-conditions" data-refrence="<?php echo esc_attr( $selected_refrence ); ?>">
					<?php
						$rank_events       = mycred_get_rank_events();
						$requirement_class = new $rank_events[ $selected_refrence ]['class']();
						$requirement_class->settings( $data );
					?>
					</div>
				</div>
				<div class="row">
					<div class="col-md-1 mycred-meta-lbl">
						<label for="cname">URL: </label>
					</div>
					<div class="col-md-11 flex-grow-1">
					<?php
						$atts = array(
							'placeholder' => 'URL',
							'class'       => 'mrr-url',
							'data-index'  => 'url',
						);

						if ( ! empty( $data['url'] ) ) {
							$atts['value'] = $data['url'];
						}

						mycred_create_input_field( $atts );
						?>
					</div>
				</div>
				</div>
			</li>
		<?php

		$content = ob_get_clean();
		$html    = apply_filters( 'mycred_rank_requirement_html', $content, $data, $sequence );

		if ( $echo ) {
			echo $html;// phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
		} else {
			return $html;
		}
	}
endif;

if ( ! function_exists( 'mycred_rank' ) ) :
	function mycred_rank( $id, $force = false ) {

		$rank_cache_key = 'mycred_rank_' . $id;
		$rank           = wp_cache_get( $rank_cache_key );

		if ( false === $rank || $force ) {

			$rank = new myCred_Rank_Object( $id );
			wp_cache_set( $rank_cache_key, $rank );

		}

		return $rank;
	}
endif;

if ( ! function_exists( 'mycred_get_ranks_cache' ) ) :
	function mycred_get_ranks_cache() {

		return mycred_get_option( 'mycred_rank_cache' );
	}
endif;

if ( ! function_exists( 'mycred_get_users_rank_by_type' ) ) :
	function mycred_get_users_rank_by_type( $user_id, $rank_type_id ) {

		return mycred_get_user_meta( $user_id, 'mycred_current_rank_', $rank_type_id, true );
	}
endif;

if ( ! function_exists( 'mycred_update_user_ranks' ) ) :
	function mycred_update_user_ranks( $user_id, $ranks ) {

		return mycred_update_user_meta( $user_id, 'mycred_ranks', '', $ranks );
	}
endif;

if ( ! function_exists( 'mycred_update_rank_cache' ) ) :
	function mycred_update_rank_cache( $type, $data ) {

		$ranks_cache = mycred_get_ranks_cache();
		$old_cache   = $ranks_cache;

		$ranks_cache['ranks'][ $data['id'] ] = $data;

		if ( empty( $ranks_cache['sequence'] ) ) {

			$ranks_cache['sequence'] = array( $type => array( $data['id'] ) );

		} elseif ( empty( $ranks_cache['sequence'][ $type ] ) ) {

				$ranks_cache['sequence'][ $type ] = array( $data['id'] );

		} else {

			$oldIndex = array_search( $data['id'], $ranks_cache['sequence'][ $type ] );

			if ( false !== $oldIndex ) {

				unset( $ranks_cache['sequence'][ $type ][ $oldIndex ] );
				$ranks_cache['sequence'][ $type ] = array_values( $ranks_cache['sequence'][ $type ] );

			}

			if ( ! empty( $data['is_default'] ) ) {

				array_unshift( $ranks_cache['sequence'][ $type ], $data['id'] );

			} else {

				$position = -1;

				foreach ( $ranks_cache['sequence'][ $type ] as $key => $rank_id ) {

					if ( absint( $data['priority'] ) == absint( $ranks_cache['ranks'][ $rank_id ]['priority'] ) ) {

						$position = ( absint( $data['id'] ) > absint( $rank_id ) ) ? absint( $key ) + 1 : absint( $key );
						break;

					} elseif ( absint( $data['priority'] ) < absint( $ranks_cache['ranks'][ $rank_id ]['priority'] ) ) {

						$position = absint( $key );
						break;

					}
				}

				if ( $position < 0 ) {
					$ranks_cache['sequence'][ $type ][] = $data['id'];
				} else {
					array_splice( $ranks_cache['sequence'][ $type ], $position, 0, $data['id'] );
				}
			}
		}

		return mycred_update_option( 'mycred_rank_cache', apply_filters( 'mycred_rank_cache', $ranks_cache, $type, $data, $old_cache ) );
	}
endif;

if ( ! function_exists( 'array_key_first' ) ) :
	function array_key_first( array $arr ) {

		foreach ( $arr as $key => $value ) {
			return $key;
		}

		return null;
	}
endif;

if ( ! function_exists( 'mycred_get_rank_events' ) ) :
	function mycred_get_rank_events() {

		$mycred_registered_references = mycred_get_all_references();

		$events = array_map(
			function ( $reference ) {
				return array(
					'title' => $reference,
					'class' => 'myCred_Rank_Default_Requirement',
					'group' => 'refrences_group',
				);
			},
			$mycred_registered_references
		);

		$events['registration']['class'] = 'myCred_Rank_Registration_Requirement';
		$events['link_click']['class']   = 'myCred_Rank_Link_Click_Requirement';
		$events['balance_reached']       = array(
			'title' => 'Balance Reached',
			'class' => 'myCred_Rank_Balance_Reached_Requirement',
			'group' => 'other_group',
		);
		$events['earned_points_amount']  = array(
			'title' => 'Earned an amount of Points',
			'class' => 'myCred_Rank_Earned_Points_Amount_Requirement',
			'group' => 'other_group',
		);

		return apply_filters( 'mycred_get_rank_events', $events );
	}
endif;

if ( ! function_exists( 'mycred_mark_rank_requirement' ) ) :
	function mycred_mark_rank_requirement( $user_id, $rank_id, $requirement ) {

		$user_meta = mycred_get_user_meta( $user_id, 'mycred_rank_requirement_', $rank_id, true );

		if ( empty( $user_meta ) ) {
			$user_meta = array();
		}

		if ( ! in_array( $requirement, $user_meta ) ) {

			$user_meta[] = $requirement;

			mycred_update_user_meta( $user_id, 'mycred_rank_requirement_', $rank_id, $user_meta );

		}

		return $user_meta;
	}
endif;

if ( ! function_exists( 'mycred_remove_rank_from_cache' ) ) :
	function mycred_remove_rank_from_cache( $rank_id ) {

		$ranks_cache = mycred_get_ranks_cache();

		if ( ! empty( $ranks_cache['ranks'][ $rank_id ] ) ) {
			unset( $ranks_cache['ranks'][ $rank_id ] );
		}

		if ( ! empty( $ranks_cache['sequence'] ) ) {

			$type = get_the_terms( $rank_id, 'mycred_rank_types' );

			if ( ! empty( $type[0]->term_id ) && ! empty( $ranks_cache['sequence'][ $type[0]->term_id ] ) ) {

				$key = array_search( $rank_id, $ranks_cache['sequence'][ $type[0]->term_id ] );

				if ( false !== $key ) {

					unset( $ranks_cache['sequence'][ $type[0]->term_id ][ $key ] );

					if ( empty( $ranks_cache['sequence'][ $type[0]->term_id ] ) ) {

						unset( $ranks_cache['sequence'][ $type[0]->term_id ] );

					}
				}
			}
		}

		mycred_update_option( 'mycred_rank_cache', $ranks_cache );
	}
endif;

