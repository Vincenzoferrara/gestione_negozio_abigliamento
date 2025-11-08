<?php
if ( ! defined( 'MYCRED_RANK_PLUS_VERSION' ) ) exit;

if ( ! class_exists( 'myCred_Rank_Badge_Achieved_Requirement' ) ) :
	class myCred_Rank_Badge_Achieved_Requirement extends myCRED_Rank_Requirement {

		/**
		 * Construct
		 */
		function __construct() {

			parent::__construct( 'badge_achieved' );

		}

		public function has_met( $user_id, $requirement ) {

			if ( $user_id === false || empty( $requirement['badge_achieved_badge'] ) ) return false;

			$badge_id = absint( $requirement['badge_achieved_badge'] );
			$badge    = mycred_badge_plus_object( $badge_id );
			$has_met  = false;
			$amount   = absint( $requirement['amount'] );

			if ( $badge->user_has_badge( $user_id, $badge_id ) ) {
				
				if ( $amount == 1 ) {
					
					$has_met = true;

				}
				elseif ( $amount > 1 ) {

					$users_badges = mycred_get_user_meta( $user_id, 'mycred_badge_plus_ids', '', true );

					if ( empty( $users_badges[ $badge_id ] ) ) return false;

					$badge_stamps 			= $users_badges[ $badge_id ];
					$met_requirement_amount = ( count( $badge_stamps ) >= $amount );
					$limit_amount 			= absint( $requirement['limit'] );

					if ( $requirement['limit_by'] == 'no_limit' ) {
						
						$has_met = $met_requirement_amount;
					
					}
					else {

						if ( $met_requirement_amount ) {

							$has_met = $this->has_met_in_specified_time( $badge_stamps, $amount, $limit_amount, $requirement['limit_by'] );

						}	

					}

				}

			}

			return $has_met;

		}

		public function template( $data ) {
			
			$badge_types = mycred_badge_types_as_options();
			$badges      = array();

			$selected_type  = ! empty( $data['badge_achieved_type'] ) ? $data['badge_achieved_type'] : '';
			$selected_badge = ! empty( $data['badge_achieved_badge'] ) ? $data['badge_achieved_badge'] : '';
			$limit		    = ! empty( $data['limit'] ) ? $data['limit'] : '';
			$limit_by       = ! empty( $data['limit_by'] ) ? $data['limit_by'] : 'day';
			$amount         = ! empty( $data['amount'] ) ? $data['amount'] : '';

			if ( ! empty( $badge_types ) && ! empty( array_key_first( $badge_types ) ) ) {
				
				if ( empty( $selected_type ) ) $selected_type = array_key_first( $badge_types );

				$results = mycred_badge_get_badges_by_type_id( $selected_type );

				if ( ! empty( $results ) ) {
	
					foreach ( $results as $badge ) 
						$badges[ $badge->ID ] = $badge->post_title;
	
				}

			}

			$type_atts = array(
				'class' => 'mycred-ui-form mycred-ui-select-fit-content mycred-select2 mrr-badge-achieved-types',
				'data-index' => 'badge_achieved_type',
				'style' => 'min-width: 150px;max-width: 100%;'
			);

			$badge_atts = array(
				'class' => 'mycred-ui-form mycred-ui-select-fit-content mycred-select2 mrr-badge-achieved-badges',
				'data-index' => 'badge_achieved_badge',
				'style' => 'min-width: 150px;max-width: 100%;'
			);

			echo '<div class="mrr-rank-achieved-badge-container mb-4">';

			mycred_create_select_field( $badge_types, $selected_type, $type_atts );
			mycred_create_select_field( $badges, $selected_badge, $badge_atts );
			
			echo '</div>';

			$this->times_field( $amount );
			$this->limit_and_limit_by_fields( $limit, $limit_by );
		
		}

		public function times_field( $amount ) {

			?>
			<div class="mycred-meta-requirement-limit-wrapper mb-4" style="min-width: fit-content;">
    			<div class="limit-container">
    				<?php 

    				$atts = array(
						'type' => 'number',
						'value' => '1',		
						'min' => 1,
						'class' => 'mrr-amount',
						'style' => 'max-width: 60px;',
						'data-index' => 'amount'
					);

					if ( ! empty( $amount ) )
						$atts['value'] = $amount;

					mycred_create_input_field( $atts );

    				?>
    				<label>time(s)</label>
    			</div>
    		</div>
			<?php

		}

		public function has_met_in_specified_time( $badge_stamps, $earned_amount, $limit_amount, $limit_by ) {

			$has_met = false;
			
			foreach ( $badge_stamps as $key => $starting_stamp ) {

				$temp_stamps    = $badge_stamps;
				
				unset( $temp_stamps[ $key ] );
				
				$specified_time = $this->get_specified_times( $starting_stamp, $limit_by, $limit_amount );
				$earned_in_time = array();

				foreach ( $temp_stamps as $comparing_stamp ) {

					if ( $comparing_stamp >= $specified_time['start'] && $comparing_stamp <= $specified_time['end'] ) {

						$earned_in_time[] = $comparing_stamp;

						if ( count( $earned_in_time ) >= $earned_amount ) {
						
							$has_met = true;
							break;

						}

					}

				}

				if ( $has_met ) break;

			}

			return $has_met;

		}

		public function get_specified_times( $starting_stamp, $limit_by, $limit_amount ) {

			$times = array();

			$limit_amount = ( $limit_amount > 0 ? $limit_amount - 1 : 0 );
			
			switch ( $limit_by ) {

				case 'day':
					$times['start'] = strtotime( date( "Y-m-d h:i:sa", $starting_stamp ) . " midnight" );
					$times['end']   = strtotime( "$limit_amount day 23:59:59", $times['start'] );
					break;
				case 'week':
					$week_days   	 = array( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' );
					$week_starts 	 = get_option( 'start_of_week' );
					$badge_stamp_day = date( 'l', $starting_stamp );
					$times['start']  = strtotime( "midnight", $starting_stamp );

					if ( $week_days[ $week_starts ] != $badge_stamp_day )
						$times['start'] = strtotime( "last " . $week_days[ $week_starts ], $starting_stamp );

					$times['end']    = strtotime( "+$limit_amount week -1 days 23:59:59", $times['start'] );
					break;
				case 'month':
					$times['start'] = strtotime( date( 'Y-m-01', $starting_stamp ) );
					$times['end']   = strtotime( date( 'Y-m-t 23:59:59', strtotime( "$limit_amount month", $times['start'] ) ) );
					break;
				case 'year':
					$times['start'] = strtotime( date( 'Y-01-01', $starting_stamp ) );
					$times['end']   = strtotime( date( 'Y-12-31', $times['start'] ) . "$limit_amount years 23:59:59" );
					break;
				default:
					break;
			
			}

			return $times;

		}

	}
endif;