<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( ! class_exists( 'myCred_Rank_Default_Requirement' ) ) :
	class myCred_Rank_Default_Requirement extends myCRED_Rank_Requirement {

		/**
		 * Construct
		 */
		function __construct() {

			parent::__construct( 'default' );
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

			$having = "COUNT(*)";
			if ( $requirement['amount_by'] != 'times' ) {
				$having = "SUM(creds)";
			}

			$between = $this->time_filter( $requirement['limit'], $requirement['limit_by'] );

			$amount = $wpdb->get_var( 
				$wpdb->prepare( 
					"SELECT $having FROM %i WHERE ctype = %s AND ref = %s AND user_id = %d $between;", 
					$mycred_log_table, 
					$requirement['point_type'], 
					$requirement['reference'], 
					$user_id 
				) 
			);

			if ( $amount === null ) {
				$amount = 0;
			}

			return $amount >= $requirement['amount'];
		}

		public function template( $data ) {

			$point_type = ! empty( $data['point_type'] ) ? $data['point_type'] : MYCRED_DEFAULT_TYPE_KEY;
			$amount     = ! empty( $data['amount'] ) ? $data['amount'] : '';
			$amount_by  = ! empty( $data['amount_by'] ) ? $data['amount_by'] : 'times';
			$limit      = ! empty( $data['limit'] ) ? $data['limit'] : '';
			$limit_by   = ! empty( $data['limit_by'] ) ? $data['limit_by'] : 'day';

			$this->point_type_field( $point_type );
			$this->amoun_and_amount_by_fields( $amount, $amount_by );
			$this->limit_and_limit_by_fields( $limit, $limit_by );
		}
	}
endif;
