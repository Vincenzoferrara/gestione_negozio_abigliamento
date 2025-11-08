<?php
/**
 * Register Badge Post Type
 * @since 1.0.0
 * @version 1.0.0
 */
if ( ! function_exists( 'mycred_register_badge_plus' ) ):
	function mycred_register_badge_plus() {

        $labels = array(
            'name'                  => __( 'Badges', 'mycred' ),
            'singular_name'         => __( 'Badge', 'mycred' ),
            'add_new'               => __( 'Add New Badge', 'mycred' ),
            'add_new_item'          => __( 'Add New Badge', 'mycred' ),
            'edit_item'             => __( 'Edit Badge', 'mycred' ),
            'new_item'              => __( 'New Badge', 'mycred' ),
            'all_items'             => __( 'All Badges', 'mycred' ),
            'view_item'             => __( 'View Badge', 'mycred' ),
            'search_items'          => __( 'Search Badges', 'mycred' ),
            'featured_image'        => __( 'Badge Logo', 'mycred' ),
            'set_featured_image'    => __( 'Set badge logo', 'mycred' ),
            'remove_featured_image' => __( 'Remove badge logo', 'mycred' ),
            'use_featured_image'    => __( 'Use as Logo', 'mycred' ),
            'not_found'             => __( 'No badge found', 'mycred' ),
            'not_found_in_trash'    => __( 'No badge found in Trash', 'mycred' ), 
            'parent_item_colon'     => '',
            'menu_name'             => __( 'Badge Plus', 'mycred' )
        );

        // Support
        $supports = array( 'title', 'thumbnail', 'excerpt', 'editor', 'author', 'custom-fields' );

        // Custom Post Type Attributes
        $args = array(
            'labels'               => $labels,
            'supports'             => $supports,
            'hierarchical'         => false,
            'public'               => true,
            'publicly_queryable'   => true,
            'show_ui'              => true,
            'show_in_menu'         => true,
            'show_in_nav_menus'    => false,
            'show_in_admin_bar'    => false,
            'menu_position'        => 20,
            'can_export'           => true,
            'has_archive'          => true,
            'exclude_from_search'  => true,
            'capability_type'      => 'post',
            'show_in_rest'         => true,
            'menu_icon'            => 'dashicons-awards',
            'taxonomies'           => array( MYCRED_BADGE_PLUS_TYPE ),
            'rewrite'              => array( 
            	'slug' 		 => MYCRED_BADGE_PLUS_KEY,
            	'with_front' => true
            )
        );

        register_post_type( MYCRED_BADGE_PLUS_KEY, apply_filters( 'mycred_register_badge_plus', $args ) );

    }
endif;

/**
 * Register Badges-Plus Taxonomy
 * @since 1.0.0
 * @version 1.0.0
 */
if ( !function_exists( 'mycred_register_badge_types' ) ) :
	function mycred_register_badge_types() {

	    $labels = [
	        'name' => __( 'Badge Types', 'mycred' ),
	        'menu_name' =>  __( 'Badge Types', 'mycred' ),
	        'all_items' => __( 'Badge Types', 'mycred' ),
	        'add_new_item' => __( 'Add New Badge Type', 'mycred' ),
	        'parent_item' => __( 'Parent Badge Type', 'mycred' ),
	    ];

	    $args = [
	        'labels' => $labels,
	        'show_ui' => true,
	        'show_in_menu'  => true,
	        'show_admin_column' => false,
	        'query_var' => true,
	        'rewrite'       => array(
	            'slug' => MYCRED_BADGE_PLUS_SLUG
	        ),
	        'show_in_rest'  => true,
	        'hierarchical'  => true,
	    ];

	    register_taxonomy(
	        MYCRED_BADGE_PLUS_TYPE,
	        MYCRED_BADGE_PLUS_KEY,
	        $args
	    );

	}
endif;

if ( ! function_exists( 'mycred_badge_requirement_html' ) ) :
	function mycred_badge_requirement_html( $data = array(), $sequence = 1, $echo = true ) {

		ob_start();

		$label       = ! empty( $data['label'] ) ? $data['label'] : '';
		$required    = ! empty( $data['required'] ) ? $data['required'] : 'required';
		$post_types  = ! empty( $data['post_types'] ) ? $data['post_types'] : '';
		$single_post = ! empty( $data['single_post'] ) ? $data['single_post'] : '';
		$point_type  = ! empty( $data['point_type'] ) ? $data['point_type'] : MYCRED_DEFAULT_TYPE_KEY;
		$amount_by   = ! empty( $data['amount_by'] ) ? $data['amount_by'] : 'times';
		$limit_by    = ! empty( $data['limit_by'] ) ? $data['limit_by'] : 'day';
		$selected_refrence = ! empty( $data['reference'] ) ? $data['reference'] : 'registration';

		?>
		<li class="mycred-meta-repeater">
		  	<div class="mycred-meta-repeater-header">
		  		<div class="title">
		  			<span class="mycred-sortable-sequence"><?php echo empty( $sequence ) ? '{{sequence}}' : absint( $sequence ); ?> - </span>
		  			<span class="mrr-title"><?php echo esc_html( $label );?></span>
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
	        			<label for="cname"><?php echo esc_html( 'Label: ', 'mycred' ); ?></label>
	        		</div>
	        		<div class="col-md-9 flex-grow-1">
	        			<?php 
		        			$atts = array(
								'class' => 'mb-4 mrr-label',
								'placeholder' => 'Requirement label',
								'data-index'  => 'label'
							);

		        			if ( ! empty( $label ) )
		        				$atts['value'] = $label;

		        			mycred_create_input_field( $atts );
		        		?>
	        		</div>
	        		<div class="col-md-2">
	        			<?php 
		        			$is_required_options = array(
		        				'required' => 'Required',
		        				'optional' => 'Optional'
		        			);
		        			$is_required_atts = array(
								'class' => 'mycred-ui-form mb-4 mrr-is-required',
								'data-index' => 'required'
							);
		        			mycred_create_select_field( $is_required_options, $required, $is_required_atts );
	        			?>
	        		</div>
	        	</div>
	        	<div class="row mycred-meta-requirement-row">
	        		<div class="col-md-1 mycred-meta-lbl">
	        			<label for="cname"><?php echo esc_html__( 'When: ', 'mycred' ); ?></label>
	        		</div>
	        		<div class="col-md-4 mb-4" data-column="refrence">
	        		<?php 
	        			$reference_ids_atts = array(
						    'class' => 'form-control mycred-select2 mrr-refrence',
						    'data-index' => 'reference',
						    'style' => 'width: 100%;'
						);

	        			$event_groups = apply_filters( 'mycred_badge_requirement_event_groups', array(
								'refrences_group' => array( 'label' => 'Refrences' ),
								'other_group' => array( 'label' => 'Other' )
							)
	        			);

	        			$badge_events = mycred_get_badge_events();

	        			foreach ( $badge_events as $key => $event ) {

	        				$event_groups[ $event['group'] ]['options'][ $key ] = $event['title'];
	        					
	        			}
	        			
	        			mycred_create_select_field( $event_groups, $selected_refrence, $reference_ids_atts );
	        		?>
	        		</div>
	        		<div class="col-md-7 flex-grow-1 mycred-meta-req-conditions" data-refrence="<?php echo esc_attr( $selected_refrence );?>">

	        			<?php 

							$badge_events = mycred_get_badge_events();
							$requirement_class = new $badge_events[ $selected_refrence ]['class']();
							$requirement_class->settings( $data );

	        			?>

	        		</div>
	        	</div>
	        	<div class="row">
	        		<div class="col-md-1 mycred-meta-lbl">
	        			<label for="cname"><?php echo esc_html__( 'URL: ', 'mycred' ); ?></label>
	        		</div>
	        		<div class="col-md-11 flex-grow-1">
	        			<?php 
		        			$atts = array(
								'placeholder' => 'URL',
								'class' => 'mrr-url',
								'data-index' => 'url'
							);

		        			if ( ! empty( $data['url'] ) )
		        				$atts['value'] = $data['url'];

		        			mycred_create_input_field( $atts );
		        		?>
	        		</div>
	        	</div>
	  		</div>
	  	</li>
		<?php
		
		$content = ob_get_clean();
		$html    = apply_filters( 'mycred_badge_requirement_html', $content, $data, $sequence );

		if ( $echo )
			echo $html; // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
		else
			return $html;

	}
endif;

if ( ! function_exists( 'mycred_get_badge_events' ) ) :
	function mycred_get_badge_events() {

		$mycred_registered_references = mycred_get_all_references();

		$events = array_map( function( $reference ) {
			return array( 
				'title' => $reference, 
				'class' => 'myCred_Badge_Default_Requirement',
				'group' => 'refrences_group'
			);
		}, $mycred_registered_references );

		$events['registration']['class'] = 'myCred_Badge_Registration_Requirement';
		$events['link_click']['class']   = 'myCred_Badge_Link_Click_Requirement';
		$events['balance_reached']       = array( 
			'title' => 'Balance Reached', 
			'class' => 'myCred_Badge_Balance_Reached_Requirement',
			'group' => 'other_group'
		);
		$events['earned_points_amount']  = array(
			'title' => 'Earned an amount of Points', 
			'class' => 'myCred_Badge_Earned_Points_Amount_Requirement',
			'group' => 'other_group'
		);

		return apply_filters( 'mycred_get_badge_events', $events );

	}
endif;

/**
 * Get Badge IDs
 * Returns all published badge post IDs.
 * @since 1.5
 * @version 1.1
 */
if ( ! function_exists( 'mycred_badge_plus_ids_requirements' ) ) :
	function mycred_badge_plus_ids_requirements() {

		$badge_ids = wp_cache_get( 'mycred_badge_plus_', MYCRED_SLUG );

		if ( $badge_ids !== false && is_array( $badge_ids ) ) return $badge_ids;

		global $wpdb;

		$table     		= mycred_get_db_column( 'posts' );
		$postmeta_table = mycred_get_db_column( 'postmeta' );

		$badge_ids = $wpdb->get_results( 
			$wpdb->prepare( 
				"SELECT p.ID, pm.meta_value 
				FROM %i as p, %i as pm
				WHERE post_type = %s 
				AND p.ID = pm.post_id 
				AND pm.meta_key = 'mycred_badge_requirements'
				AND p.post_status = 'publish' 
				ORDER BY p.post_date ASC;",
				$table,
				$postmeta_table,
				MYCRED_BADGE_PLUS_KEY 
			) 
		);

		wp_cache_set( 'mycred_badge_plus_', $badge_ids, MYCRED_SLUG );

		return apply_filters( 'mycred_get_badge_ids', $badge_ids );

	}
endif;

if ( ! function_exists( 'mycred_get_badge_plus_ids' ) ) :
	function mycred_get_badge_plus_ids() {

		$badge_ids = wp_cache_get( 'mycred_badge_plus_', MYCRED_SLUG );

		if ( $badge_ids !== false && is_array( $badge_ids ) ) return $badge_ids;

		global $wpdb;

		$table = mycred_get_db_column( 'posts' );

		$badge_ids = $wpdb->get_results( 
			$wpdb->prepare( "
				SELECT p.ID
				FROM %i as p
				WHERE post_type = %s 
				AND p.ID
				AND p.post_status = 'publish' 
				ORDER BY p.post_date ASC;",
				$table,
				MYCRED_BADGE_PLUS_KEY 
			) 
		);

		wp_cache_set( 'mycred_badge_plus_', $badge_ids, MYCRED_SLUG );

		return apply_filters( 'mycred_get_badge_ids', $badge_ids );

	}
endif;

if ( ! function_exists( 'mycred_badge_plus_object' ) ) :
	function mycred_badge_plus_object( $id, $force = false ) {

		$badge_cache_key = 'mycred_badge_plus_'. $id;
	    $badge = wp_cache_get( $badge_cache_key );

	    if ( false === $badge || $force ) {
	        
	        $badge = new myCRED_Badge_plus( $id );
	        wp_cache_set( $badge_cache_key, $badge );

	    }
	  
	    return $badge;

	}
endif;

if ( ! function_exists( 'mycred_count_users' ) ) :
	function mycred_count_users( $user_id = NULL, $badge_id = 0 ) {

		if ( $user_id === 0 ) return false;
		
		$user_id = absint( $user_id );

		$badges = mycred_get_user_meta( $user_id, 'mycred_badge_plus_ids', '', true );

		if( ! empty( $badges[$badge_id] ) ){
			
			if ( count( $badges[$badge_id] ) > 1 ) {
				return absint( count( $badges[$badge_id] ) );
			}
			else{
				return 1;
			}

		}

		return 0;

	}
endif;

if ( ! function_exists( 'mycred_bp_badges_user_exceeded_max_earnings' ) ) :
	function mycred_bp_badges_user_exceeded_max_earnings(  $badge, $user_id = 0, $achievement_id = 0 ) {

	    // Sanitize vars
	    $user_id = absint( $user_id );
	    $achievement_id = absint( $achievement_id );

	    // Global max earnings
		$global_max_earnings = mycred_get_post_meta( $achievement_id, 'mycred_global_badge_plus', true );

		// -1, 0 or empty means unlimited earnings
	    if( $global_max_earnings === '-1' || $global_max_earnings === '0' || empty( $global_max_earnings ) ) {
	        $global_max_earnings = 0;
	    }

	    $global_max_earnings = absint( $global_max_earnings );

	    // Only check global max earnings if isn't setup as unlimited
	    if( $global_max_earnings > 0 ) {

	        $earned_times = $badge->earned;

	        // Bail if achievement has exceeded its global max earnings
	        if( $earned_times >= $global_max_earnings ) {
	            return false;
	        }

	    }

	 	// Per user max earnings
		$max_earnings = mycred_get_post_meta( $achievement_id, 'mycred_user_badge_plus', true );

		// Unlimited maximum earnings per user check
	    if( $max_earnings === '-1' || $max_earnings === '0' || empty( $max_earnings ) ) {
			return true;
	    }

		// If the achievement has an earning limit per user, and we've earned it before...
		if ( $max_earnings && $badge->user_has_badge( $user_id, $achievement_id ) ) {


			// If we've earned it as many (or more) times than allowed, then we have exceeded maximum earnings, thus true
			if ( mycred_count_users( $user_id, $achievement_id ) >= $max_earnings ) {
				return false;
	        }

		}
		// The post has no limit, or we're under it
		return true;
	}
endif;

if ( ! function_exists( 'mycred_get_users_badges_plus' ) ) :
	function mycred_get_users_earned_badge_plus( $user_id = NULL ) {

		if ( $user_id == NULL ) return false;

		if ( ! empty( $user_id ) ) {

			$badge_ids = mycred_get_user_meta( $user_id, 'mycred_badge_plus_ids', '', true );
			if ( ! empty( $badge_ids ) ) {
				foreach ( $badge_ids as $id => $date ) {
					foreach ($date as $key => $earned) {
						$clean_ids[] = absint( $earned );
					}
				}
				return apply_filters( 'mycred_get_users_badges', $clean_ids, $user_id );
			}
		
		}
		return array();
	}
endif;

if( ! function_exists( 'mycred_mark_badge_requirement' ) ) :
    function mycred_mark_badge_requirement( $user_id, $badge_id, $requirement ) {
        
        $user_meta = mycred_get_user_meta( $user_id, 'mycred_badge_requirement_', $badge_id, true );

        if ( empty( $user_meta ) ) $user_meta = array();

        if ( ! in_array( $requirement, $user_meta ) ) {

        	$user_meta[] = $requirement;
        
        	mycred_update_user_meta( $user_id, 'mycred_badge_requirement_', $badge_id, $user_meta );
        	
        }

        return $user_meta;

    }
endif;


// for future use
if ( ! function_exists( 'mycred_bp_earned_by_require_steps' ) ) :	 
	function mycred_bp_earned_by_require_steps(){
	?>
	<div class="mycred-boder-line" style='border-bottom: 1px solid #e9e9e9;'>
	    <div class="mycred-setting-badge-plus container" style="margin: 10px; ">
	        <div class="row" style="margin-bottom: 20px;"> 
	            <div class="col-sm-2 col-md-2">
	                 <label><?php echo esc_html__( 'Earned By Requirements: ', 'mycred' ); ?></label>
	             </div>
	             <div class="col-sm-10 col-md-10">
	                <div class="row">
	                    <div class="col-sm-12 col-md-12">
	                        <?php 
	                        $steps = array(
	                            'complete_steps' => 'Completing Steps',
	                            'minimum_points' => 'Minimum Number of Points',
	                            'reach_badge' => 'Reach a badge',
	                            'admin_award' => 'Admin-awarded Only'
	                        );
	                        $steps_atts = array(
	                            'class' => 'mycred-ui-form mycred-ui-select-fit-content mb-4 mrr-point-type',
	                            'name' => 'steps'
	                        );
	                        mycred_create_select_field( $steps, $steps, $steps_atts );
	                        ?>
	                    </div>
	                    <p class="description"><?php echo esc_html__( 'How this achievement can be earned.' , 'mycred' ); ?></p>
	                </div>
	            </div>
	            
	        </div>
	    </div>
	</div>
	<?php
	}
endif;