<?php
if ( ! defined( 'ABSPATH' ) ) exit;

if ( ! class_exists( 'myCred_Badge_Registration_Requirement' ) ) :
	class myCred_Badge_Registration_Requirement extends myCRED_Badge_Requirement {

		/**
		 * Construct
		 */
		function __construct() {

			parent::__construct( 'registration' );

		}

		public function has_met( $user_id, $requirement, $badge_id = 0 ) {

			if ( $user_id === false || empty( $requirement ) ) return false;

			global $wpdb, $mycred_log_table;

			if ( empty( $requirement['point_type'] ) )
				$requirement['point_type'] = MYCRED_DEFAULT_TYPE_KEY;

			$mycred = mycred( $requirement['point_type'] );
			if ( $mycred->exclude_user( $user_id ) ) return false;

			$result = $wpdb->get_var( 
				$wpdb->prepare( 
					"SELECT COUNT(*) FROM %i WHERE ctype = %s AND ref = %s AND user_id = %d LIMIT 1;", 
					$mycred_log_table,
					$requirement['point_type'], 
					$this->id, 
					$user_id 
				) 
			);

			return ! empty( $result );

		}

		public function template( $data ) {

			$point_type = ! empty( $data['point_type'] ) ? $data['point_type'] : MYCRED_DEFAULT_TYPE_KEY;

			$this->point_type_field( $point_type );

		}

	}
endif;