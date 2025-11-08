<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * myCRED_Rank_Requirement class
 *
 * @since 2.5
 * @version 1.0
 */
if ( ! class_exists( 'myCRED_Rank_Requirement' ) ) :
	abstract class myCRED_Rank_Requirement {

		public $id = false;

		/**
		 * Construct
		 */
		function __construct( $id ) {

			$this->id = $id;
		}

		abstract protected function has_met( $user_id, $requirement );

		abstract protected function template( $data );

		public function settings( $data, $echo = true ) {

			ob_start();

			$this->template( $data );

			$content = ob_get_clean();

			if ( $echo ) {
				echo $content;// phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
			} else {
				return $content;
			}
		}

		public function point_type_field( $selected = MYCRED_DEFAULT_TYPE_KEY ) {

			$types = mycred_get_types();

			$atts = array(
				'class'      => 'mycred-ui-select-fit-content mb-4 mrr-point-type',
				'data-index' => 'point_type',
			);

			mycred_create_select_field( $types, $selected, $atts );
		}

		public function amoun_and_amount_by_fields( $amount = '', $amount_by = 'times' ) {

			$atts = array(
				'type'       => 'number',
				'value'      => '1',
				'min'        => 1,
				'class'      => 'mb-4 mrr-amount',
				'style'      => 'max-width: 60px;',
				'data-index' => 'amount',
			);

			if ( ! empty( $amount ) ) {
				$atts['value'] = $amount;
			}

			mycred_create_input_field( $atts );

			$amount_by_options = array(
				'times'   => 'Time(s)',
				'intotal' => 'In Total',
			);
			$amount_by_atts    = array(
				'class'      => 'mycred-ui-form mycred-ui-select-fit-content mb-4 mrr-amount-by',
				'data-index' => 'amount_by',
			);
			mycred_create_select_field( $amount_by_options, $amount_by, $amount_by_atts );
		}

		public function limit_and_limit_by_fields( $limit = '', $limit_by = 'day' ) {
			?>
			<div class="mycred-meta-requirement-limit-wrapper mb-4">
				<div class="limit-container">
					<label>limited to</label>
					<?php
						$atts = array(
							'type'       => 'number',
							'value'      => '1',
							'min'        => 1,
							'style'      => 'max-width: 60px;',
							'class'      => 'mrr-limit',
							'data-index' => 'limit',
							'limit-by'   => $limit_by,
						);

						if ( ! empty( $limit ) ) {
							$atts['value'] = $limit;
						}

						mycred_create_input_field( $atts );

						$limit_by_options = array(
							'no_limit' => 'No Limit',
							'day'      => '/ Day',
							'week'     => '/ Week',
							'month'    => '/ Month',
							'year'     => '/ Year',
						);
						$limit_by_atts    = array(
							'class'      => 'mycred-ui-form mycred-ui-select-fit-content mrr-limit-by',
							'data-index' => 'limit_by',
						);
						mycred_create_select_field( $limit_by_options, $limit_by, $limit_by_atts );
						?>
				</div>
			</div>
			<?php
		}

		public function time_filter( $limit, $limit_by ) {

			global $wpdb;
			$limit        = absint( $limit );
			$limit_amount = $limit > 0 ? ( $limit - 1 ) * -1 : 0;
			$now          = current_time( 'timestamp' );
			$time_filter  = '';

			if ( $limit_by == 'day' ) {

				$time_filter = $wpdb->prepare( " AND time BETWEEN %d AND %d", strtotime( $limit_amount . " day midnight", $now ), $now );

			} elseif ( $limit_by == 'week' ) {

				$starting_day = array( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' );
				$week_starts  = get_option( 'start_of_week' );

				$week_limit = $limit == 0 ? 1 : $limit;
				$week       = $week_limit * -1;

				if ( $starting_day[ $week_starts ] == date( 'l' ) && $week_limit === 1 ) {
					$week = 'today midnight';
				} elseif ( $starting_day[ $week_starts ] == date( 'l' ) && $week_limit > 1 ) {
					$week = ( $week + 1 ) . ' ' . $starting_day[ $week_starts ];
				} else {
					$week = $week . ' ' . $starting_day[ $week_starts ];
				}

				$time_filter = $wpdb->prepare( " AND time BETWEEN %d AND %d " , strtotime( $week, $now ), $now );

			} elseif ( $limit_by == 'month' ) {

				$time_filter = $wpdb->prepare( " AND time BETWEEN %d AND %d " , strtotime( date( 'Y-m-01', $now ) . " " . $limit_amount . ' month' ), $now );

			} elseif ( $limit_by == 'year' ) {

				$time_filter = $wpdb->prepare( " AND time BETWEEN %d AND %d ", strtotime( date( 'Y-01-01', $now ) . " " . $limit_amount . ' year' ), $now );

			}

			return $time_filter;
		}
	}
endif;
