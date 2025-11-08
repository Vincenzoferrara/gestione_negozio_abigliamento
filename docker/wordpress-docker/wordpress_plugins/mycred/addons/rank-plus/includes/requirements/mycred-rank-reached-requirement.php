<?php
if ( ! defined( 'MYCRED_RANK_PLUS_VERSION' ) ) exit;

if ( ! class_exists( 'myCred_Rank_Reached_Requirement' ) ) :
	class myCred_Rank_Reached_Requirement extends myCRED_Rank_Requirement {

		/**
		 * Construct
		 */
		function __construct() {

			parent::__construct( 'rank_reached' );

		}

		public function has_met( $user_id, $requirement ) {

			if ( $user_id === false || empty( $requirement['rank_reached_rank'] ) ) return false;

			$rank = mycred_rank( absint( $requirement['rank_reached_rank'] ) );

			return $rank->user_has_rank( $user_id );

		}

		public function template( $data ) {
			
			$rank_types = mycred_rank_types_as_options();
			$ranks      = array();

			$selected_type = ! empty( $data['rank_reached_type'] ) ? $data['rank_reached_type'] : '';
			$selected_rank = ! empty( $data['rank_reached_rank'] ) ? $data['rank_reached_rank'] : '';

			if ( ! empty( $rank_types ) && ! empty( array_key_first( $rank_types ) ) ) {
				
				if ( empty( $selected_type ) ) $selected_type = array_key_first( $rank_types );

				$results = mycred_rank_get_ranks_by_type_id( $selected_type );

				if ( ! empty( $results ) ) {
	
					foreach ( $results as $rank ) 
						$ranks[ $rank->id ] = $rank->title;
	
				}

			}

			$type_atts = array(
				'class' => 'mycred-ui-form mycred-ui-select-fit-content mb-4 mycred-select2 mrr-rank-reached-types',
				'data-index' => 'rank_reached_type',
				'style' => 'min-width: 150px;max-width: 100%;'
			);

			$rank_atts = array(
				'class' => 'mycred-ui-form mycred-ui-select-fit-content mb-4 mycred-select2 mrr-rank-reached-ranks',
				'data-index' => 'rank_reached_rank',
				'style' => 'min-width: 150px;max-width: 100%;'
			);

			echo '<div class="mrr-rank-reached-container">';

			mycred_create_select_field( $rank_types, $selected_type, $type_atts );
			mycred_create_select_field( $ranks, $selected_rank, $rank_atts );
			
			echo '</div>';

		}

	}
endif;