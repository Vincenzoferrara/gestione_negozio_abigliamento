<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Load Birthday Hook
 * @since 1.0
 * @version 1.0
 */
if ( ! class_exists( 'myCRED_Birthday_Hook' ) ) :
	class myCRED_Birthday_Hook extends myCRED_Hook {

		protected $check_id  = NULL;
		protected $now       = 0;
		protected $this_year = 0;

		/**
		 * Construct
		 */
		function __construct( $hook_prefs, $type = MYCRED_DEFAULT_TYPE_KEY ) {

			parent::__construct( array(
				'id'       => 'birthday',
				'defaults' => array(
					'use'      => '',
					'field_id' => '',
					'creds'    => 1,
					'log'      => 'Birthday %plural%'
				)
			), $hook_prefs, $type );

			$this->check_id  = 'mycred-birthday-hook-run-' . $type;
			$this->now       = current_time( 'timestamp' );
			$this->this_year = date( 'Y', $this->now );

		}

		/**
		 * Run
		 * Runs if the hook is enabled.
		 * @since 1.0
		 * @version 1.0
		 */
		public function run() {

			if ( $this->prefs['use'] == 'buddypress' )
				add_action( 'bp_init', array( $this, 'check_today' ) );

			elseif ( $this->prefs['use'] == 'wordpress' )
				$this->check_today();

		}

		/**
		 * Daily Check
		 * @since 1.0
		 * @version 1.0
		 */
		public function check_today() {

			$today    = date( 'Ymd', $this->now );
			$last_run = get_option( $this->check_id, false );
			if ( $last_run === false || $last_run != $today ) {

				update_option( $this->check_id, $today );

				$this->birthday_check();

			}

		}

		/**
		 * Get BuddyPress Birthdays
		 * @since 1.0
		 * @version 1.0
		 */
		public function get_buddypress_birthdays() {

			global $wpdb, $bp;

			return $wpdb->get_col( $wpdb->prepare( "
				SELECT bpdata.user_id 
				FROM {$bp->profile->table_name_data} bpdata 
				LEFT JOIN {$bp->profile->table_name_fields} bpfield 
					ON ( bpfield.id = bpdata.field_id ) 
				WHERE bpfield.name = %s 
				AND bpdata.value LIKE %s;", $this->prefs['field_id'], $this->get_todays_like_date() ) );

		}

		/**
		 * Get WordPress Birthdays
		 * @since 1.0
		 * @version 1.0
		 */
		public function get_wordpress_birthdays() {

			global $wpdb;

			return $wpdb->get_col( $wpdb->prepare( "SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = %s AND meta_value LIKE %s;", $this->prefs['field_id'], $this->get_todays_like_date() ) );

		}

		/**
		 * Prep Format for LIKE
		 * Supported formats:
		 * - Y-m-d
		 * - m/d/Y
		 * - d/m/Y
		 * @since 1.0
		 * @version 1.0
		 */
		public function get_todays_like_date() {

			return apply_filters( 'mycred-format-dob-field', date( '%-m-d%', $this->now ), $this );

		}

		/**
		 * Every day, check if anyone has a birthday today.
		 * Users can only get points if they are not excluded and if
		 * they have not recevied points already this year.
		 * @since 1.0
		 * @version 1.0
		 */
		public function birthday_check() {

			if ( $this->prefs['use'] == 'buddypress' )
				$birthdays = $this->get_buddypress_birthdays();
			else
				$birthdays = $this->get_wordpress_birthdays();

			if ( ! empty( $birthdays ) ) {
				foreach ( $birthdays as $user_id ) {

					// Excluded
					if ( $this->core->exclude_user( $user_id ) ) continue;

					// Make sure we only get points once a year if users can change their date of birth
					if ( ! $this->has_entry( 'birthday', $this->this_year, $user_id ) )
						$this->core->add_creds(
							'birthday',
							$user_id,
							$this->prefs['creds'],
							$this->prefs['log'],
							$this->this_year,
							'',
							$this->mycred_type
						);

				}
			}

		}

		/**
		 * Hook Settings
		 * @since 1.0
		 * @version 1.1
		 */
		public function preferences() {

			$prefs = $this->prefs;

?>
<div class="hook-instance">
<div class="row">
	<div class="col-lg-4 col-md-4 col-sm-12 col-xs-12">
		<div class="form-group">
			<label for="<?php echo $this->field_id( 'creds' ); ?>"><?php echo $this->core->plural(); ?></label>
			<input type="text" name="<?php echo $this->field_name( 'creds' ); ?>" id="<?php echo $this->field_id( 'creds' ); ?>" value="<?php echo $this->core->number( $prefs['creds'] ); ?>" class="form-control" />
		</div>
	</div>
	<div class="col-lg-8 col-md-8 col-sm-12 col-xs-12">
		<div class="form-group">
			<label for="<?php echo $this->field_id( 'log' ); ?>"><?php _e( 'Log Template', 'mycred' ); ?></label>
			<input type="text" name="<?php echo $this->field_name( 'log' ); ?>" id="<?php echo $this->field_id( 'log' ); ?>" placeholder="<?php _e( 'required', 'mycred' ); ?>" value="<?php echo esc_attr( $prefs['log'] ); ?>" class="form-control" />
			<span class="description"><?php echo $this->available_template_tags( array( 'general' ) ); ?></span>
		</div>
	</div>
</div>
</div>
<div class="hook-instance">
<h3><?php _e( 'Date of Birth Location', 'mycred' ); ?></h3>
<div class="row">
	<div class="col-lg-6 col-md-6 col-sm-12 col-xs-12">
		<div class="form-group">
			<label for="<?php echo $this->field_id( 'use' ); ?>wp"> <?php _e( 'User Profile Field', 'mycred' ); ?></label>
			<div class="checkbox">
				<label for="<?php echo $this->field_id( 'use' ); ?>bp"><input type="radio" name="<?php echo $this->field_name( 'use' ); ?>"<?php checked( $prefs['use'], 'buddypress' ); ?> id="<?php echo $this->field_id( 'use' ); ?>bp" value="buddypress" /> <?php _e( 'BuddyPress Profile Field', 'mycred' ); ?></label>
			</div>
			<div class="checkbox">
				<label for="<?php echo $this->field_id( 'use' ); ?>wp"><input type="radio" name="<?php echo $this->field_name( 'use' ); ?>"<?php checked( $prefs['use'], 'wordpress' ); ?> id="<?php echo $this->field_id( 'use' ); ?>wp" value="wordpress" /> <?php _e( 'Custom WordPress User Meta', 'mycred' ); ?></label>
			</div>
		</div>
	</div>
	<div class="col-lg-6 col-md-6 col-sm-12 col-xs-12">
		<div class="form-group">
			<label for="<?php echo $this->field_id( 'field_id' ); ?>"><?php _e( 'Field Name / ID', 'mycred' ); ?></label>
			<input type="text" name="<?php echo $this->field_name( 'field_id' ); ?>" id="<?php echo $this->field_id( 'field_id' ); ?>" value="<?php echo esc_attr( $prefs['field_id'] ); ?>" class="form-control" />
			<span class="description"><?php _e( 'The BuddyPress field name or the custom user meta key, that identifies where the users date of birth is stored. Must be exact!', 'mycred' ); ?></span>
		</div>
	</div>
	<div class="col-lg-6 col-md-6 col-sm-12 col-xs-12"><?php _e( 'If you need more features try our <a href="https://mycred.me/store/mycred-birthday-plus/" target="_blank"><b>myCred Birthday Plus</b></a>' ) ?></div>
</div>
</div>
<?php

		}

	}
endif;
