<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( ! class_exists( 'myCred_Rank_Earned_Points_Amount_Requirement' ) ) :
	class myCred_Rank_Earned_Points_Amount_Requirement extends myCRED_Rank_Requirement {

		/**
		 * Construct
		 */
		function __construct() {

			parent::__construct( 'earned_points_amount' );
		}

		public function has_met( $user_id, $requirement ) {

			if ( $user_id === false || empty( $requirement ) ) {
				return false;
			}

			global $wpdb, $mycred_log_table;

			if ( empty( $requirement['point_type'] ) ) {
				$requirement['point_type'] = MYCRED_DEFAULT_TYPE_KEY;
			}

			$mycred = mycred( $requirement['point_type'] );
			if ( $mycred->exclude_user( $user_id ) ) {
				return false;
			}

			$result = $wpdb->get_var( 
				$wpdb->prepare( 
					"SELECT COUNT(*) FROM %i WHERE ctype = %s AND creds = %s AND user_id = %d LIMIT 1;", 
					$mycred_log_table, 
					$requirement['point_type'], 
					$requirement['earn_amount_of_points'], 
					$user_id 
				) 
			);

			return ! empty( $result );
		}

		public function template( $data ) {

			$point_type = ! empty( $data['point_type'] ) ? $data['point_type'] : MYCRED_DEFAULT_TYPE_KEY;

			$atts = array(
				'type'       => 'number',
				'value'      => '1',
				'min'        => 1,
				'class'      => 'mb-4',
				'style'      => 'max-width: 90px;',
				'data-index' => 'earn_amount_of_points',
			);

			if ( ! empty( $data['earn_amount_of_points'] ) ) {
				$atts['value'] = $data['earn_amount_of_points'];
			}

			mycred_create_input_field( $atts );

			$this->point_type_field( $point_type );
		}
	}
endif;
