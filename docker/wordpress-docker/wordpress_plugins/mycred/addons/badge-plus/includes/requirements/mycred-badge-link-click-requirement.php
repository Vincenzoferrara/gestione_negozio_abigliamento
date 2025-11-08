<?php
if ( ! defined( 'ABSPATH' ) ) exit;

if ( ! class_exists( 'myCred_Badge_Link_Click_Requirement' ) ) :
	class myCred_Badge_Link_Click_Requirement extends myCRED_Badge_Requirement {

		/**
		 * Construct
		 */
		function __construct() {

			parent::__construct( 'link_click' );

		}

		public function has_met( $user_id, $requirement, $badge_id = 0 ) {

			if ( $user_id === false || empty( $requirement ) ) return false;

			global $wpdb, $mycred_log_table;

			if ( empty( $requirement['point_type'] ) )
				$requirement['point_type'] = MYCRED_DEFAULT_TYPE_KEY;

			$mycred = mycred( $requirement['point_type'] );
			if ( $mycred->exclude_user( $user_id ) ) return false;

			$having = 'COUNT(*)';
			if ( $requirement['amount_by'] != 'times' )
				$having = 'SUM(creds)';

			if( ! array_key_exists( 'limit', $requirement ) )
				$requirement['limit'] = 0;

			$between = $this->time_filter( $requirement['limit'], $requirement['limit_by'] );

			$specific = '';

			if ( $requirement['link_click_based_on'] != 'any' ) {
				$specific = " AND data LIKE '%" . $requirement['link'] . "%'";
			}

			$amount = $wpdb->get_var( 
				$wpdb->prepare( 
					"SELECT $having FROM %i WHERE ctype = %s AND ref = %s {$specific} AND user_id = %d {$between};", 
					$mycred_log_table,
					$requirement['point_type'], 
					$requirement['reference'], 
					$user_id 
				) 
			);

			if ( $amount === NULL ) $amount = 0;

			$require_amount = $requirement['amount'] * ( mycred_count_users( $user_id, $badge_id ) + 1 );

			return $amount >= $require_amount;

		}

		public function template( $data ) {

			$link_click_based_on = ! empty( $data['link_click_based_on'] ) ? $data['link_click_based_on'] : 'any';
			$link       		 = ! empty( $data['link'] ) ? $data['link'] : '';
			$point_type 		 = ! empty( $data['point_type'] ) ? $data['point_type'] : MYCRED_DEFAULT_TYPE_KEY;
			$amount     		 = ! empty( $data['amount'] ) ? $data['amount'] : '';
			$amount_by  		 = ! empty( $data['amount_by'] ) ? $data['amount_by'] : 'times';
			$limit      		 = ! empty( $data['limit'] ) ? $data['limit'] : '';
			$limit_by   		 = ! empty( $data['limit_by'] ) ? $data['limit_by'] : 'day';
			$post_types 	     = ! empty( $data['post_types'] ) ? $data['post_types'] : '';

			$options = array(
				'any' => 'Any',
				'specific_url' => 'Specific URL',
				'specific_id' => 'Specific ID'
			);
			$atts = array(
				'class' => 'mycred-ui-form mycred-ui-select-fit-content mb-4 link_click_based_on',
				'data-index' => 'link_click_based_on'
			);
			mycred_create_select_field( $options, $link_click_based_on, $atts );

			$link_atts = array(
				'type' => 'text',
				'class' => 'mb-4 link_click_txt',
				'style' => 'max-width:300px;',
				'data-index' => 'link',
				'placeholder' => 'URL'
			);

			if ( $link_click_based_on == 'any' ) {
				$link_atts['style'] = $link_atts['style'] . 'display:none;';
			}
			elseif( $link_click_based_on == 'specific_id' ) {
				$link_atts['placeholder'] = 'ID';
			}

			if ( ! empty( $link ) )
				$link_atts['value'] = $link;

			mycred_create_input_field( $link_atts );

			$registered_post_types = get_post_types( array( 'public' => true ), 'objects' );
			$registered_post_types = array_map( function( $types ){ return $types->label; }, $registered_post_types );
			$post_types_atts = array(
			    'class' => 'mycred-ui-form mycred-ui-select-fit-content mb-4 mrr-post-types',
			    'data-index' => 'post_types',
			    'style' => 'width: 100%;'
			);
			mycred_create_select_field( $registered_post_types, $post_types, $post_types_atts );

			$this->point_type_field( $point_type );
			$this->amoun_and_amount_by_fields( $amount, $amount_by );
			$this->limit_and_limit_by_fields( $limit, $limit_by );

		}

	}
endif;