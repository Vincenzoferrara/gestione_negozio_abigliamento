<?php
if ( ! defined( 'ABSPATH' ) ) exit;

if ( ! class_exists( 'myCred_Rank_Balance_Reached_Requirement' ) ) :
	class myCred_Rank_Balance_Reached_Requirement extends myCRED_Rank_Requirement {

		/**
		 * Construct
		 */
		function __construct() {

			parent::__construct( 'balance_reached' );
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

			$users_balance = 0;

			if ( $requirement['balance_reached_based_on'] == 'current' ) {
				$users_balance = mycred_get_users_balance( $user_id, $requirement['point_type'] );
			} else {
				$users_balance = mycred_get_users_total_balance( $user_id, $requirement['point_type'] );
			}

			$result = false;

			switch ( $requirement['balance_reached_condition'] ) {
				case 'equal_to':
					$result = $requirement['balance_reached_amount'] == $users_balance;
					break;
				case 'not_equal_to':
					$result = $requirement['balance_reached_amount'] != $users_balance;
					break;
				case 'less_than':
					$result = $users_balance < $requirement['balance_reached_amount'];
					break;
				case 'greater_than':
					$result = $users_balance > $requirement['balance_reached_amount'];
					break;
				default:
					break;
			}

			return $result;
		}

		public function template( $data ) {

			$balance_reached_condition = ! empty( $data['balance_reached_condition'] ) ? $data['balance_reached_condition'] : 'equal_to';
			$balance_reached_based_on  = ! empty( $data['balance_reached_based_on'] ) ? $data['balance_reached_based_on'] : 'current';
			$point_type                = ! empty( $data['point_type'] ) ? $data['point_type'] : MYCRED_DEFAULT_TYPE_KEY;

			$options = array(
				'equal_to'     => 'equal to',
				'not_equal_to' => 'not equal to',
				'less_than'    => 'less than',
				'greater_than' => 'greater than',
			);
			$atts    = array(
				'class'      => 'mycred-ui-form mycred-ui-select-fit-content mb-4',
				'data-index' => 'balance_reached_condition',
			);
			mycred_create_select_field( $options, $balance_reached_condition, $atts );

			$balance_reached_amount_atts = array(
				'type'       => 'number',
				'value'      => '1',
				'min'        => 1,
				'class'      => 'mb-4',
				'style'      => 'max-width: 90px;',
				'data-index' => 'balance_reached_amount',
			);

			if ( ! empty( $data['balance_reached_amount'] ) ) {
				$balance_reached_amount_atts['value'] = $data['balance_reached_amount'];
			}

			mycred_create_input_field( $balance_reached_amount_atts );

			$based_on_options = array(
				'current' => 'Current Balance',
				'total'   => 'Total Balance',
			);
			$based_on_atts    = array(
				'class'      => 'mycred-ui-form mycred-ui-select-fit-content mb-4',
				'data-index' => 'balance_reached_based_on',
			);
			mycred_create_select_field( $based_on_options, $balance_reached_based_on, $based_on_atts );

			$this->point_type_field( $point_type );
		}
	}
endif;
