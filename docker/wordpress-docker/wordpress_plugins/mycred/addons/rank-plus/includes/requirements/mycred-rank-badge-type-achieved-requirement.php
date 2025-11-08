<?php
if ( ! defined( 'MYCRED_RANK_PLUS_VERSION' ) ) exit;

if ( ! class_exists( 'myCred_Rank_Badge_Type_Achieved_Requirement' ) ) :
	class myCred_Rank_Badge_Type_Achieved_Requirement extends myCRED_Rank_Requirement {

		/**
		 * Construct
		 */
		function __construct() {

			parent::__construct( 'badge_type_achieved' );

		}

		public function has_met( $user_id, $requirement ) {

			if ( $user_id === false || empty( $requirement['badge_type_achieved'] ) ) return false;

			$badge_type_id = absint( $requirement['badge_type_achieved'] );
			$has_met  	   = false;

			$badges = mycred_badge_get_badges_by_type_id( $badge_type_id, 'ids' );

			if ( ! empty( $badges ) ) {

				foreach ( $badges as $badge_id ) {

					$badge = mycred_badge_plus_object( $badge_id );

					if ( $badge->user_has_badge( $user_id, $badge_id ) ) {
						
						$has_met = true;
						break;

					}

				}

			}

			return $has_met;

		}

		public function template( $data ) {
			
			$badge_types = mycred_badge_types_as_options();
			$badges      = array();

			$selected_type = ! empty( $data['badge_type_achieved'] ) ? $data['badge_type_achieved'] : '';

			$type_atts = array(
				'class' => 'mycred-ui-form mycred-ui-select-fit-content',
				'data-index' => 'badge_type_achieved',
				'style' => 'min-width: 200px;max-width: 100%;'
			);

			mycred_create_select_field( $badge_types, $selected_type, $type_atts );
		
		}

	}
endif;