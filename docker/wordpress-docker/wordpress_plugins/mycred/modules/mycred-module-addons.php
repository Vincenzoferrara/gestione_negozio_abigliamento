<?php

if ( ! defined( 'myCRED_VERSION' ) ) exit;

/**
 * myCRED_Addons_Module class
 * @since 0.1
 * @version 1.1.1
 */

if ( ! class_exists( 'myCRED_Addons_Module' ) ) :
	class myCRED_Addons_Module extends myCRED_Module {

		/**
		 * Construct
		 */
		public function __construct( $type = MYCRED_DEFAULT_TYPE_KEY ) {

			parent::__construct( 'myCRED_Addons_Module', array(
				'module_name' => 'addons',
				'option_id'   => 'mycred_pref_addons',
				'defaults'    => array(
					'installed'     => array(),
					'active'        => array()
				),
				'labels'      => array(
					'menu'        => 'Add-ons',
					'page_title'  => 'Add-ons'
				),
				'screen_id'   => MYCRED_SLUG . '-addons',
				'accordion'   => true,
				'menu_pos'    => 30,
				'main_menu'   => true
			), $type );
			
		}

		/**
		 * Admin Init
		 * Catch activation and deactivations
		 * @since 0.1
		 * @version 1.2.2
		 */
		public function module_admin_init() {

			add_action( 'admin_enqueue_scripts', array( $this, 'mycred_addons_scripts' ) );

			// Handle actions

			$this->all_activate_deactivate();

		}

		public function mycred_addons_scripts() {

			wp_register_script('mycred-builtin-addons-script', plugins_url('addons/build/admin.bundle.js', myCRED_THIS), array('wp-element'), '1.0.0',true );
			wp_localize_script('mycred-builtin-addons-script', 'mycredAddonsData', [
				'upgraded' => apply_filters('mycred_plan_check', true ) ,
				'root' => esc_url_raw( rest_url() ),
				'nonce' => wp_create_nonce('wp_rest'),
			]);

		}

		public function all_activate_deactivate() {

			// Handle actions
			if ( isset( $_GET['addon_all_action'] ) && isset( $_GET['_token'] ) && wp_verify_nonce( sanitize_text_field( wp_unslash( $_GET['_token'] ) ), 'mycred-activate-deactivate-addon') && $this->core->user_is_point_admin() ) {

				$action = sanitize_text_field( wp_unslash( $_GET['addon_all_action'] ) );

				if ( $action == 'activate' ) {

					$this->active = array_keys( $this->installed );

				}
				elseif ( $action == 'deactivate' ) {

					$this->active = array();
					
				}

				$new_settings = array(
					'installed' => $this->installed,
					'active'    => $this->active
				);

				mycred_update_option( 'mycred_pref_addons', $new_settings );

				$url = add_query_arg( array( 'page' => MYCRED_SLUG . '-addons' ), admin_url( 'admin.php' ) );

				wp_safe_redirect( $url );
				exit;
			
			}

		}

		/**
		 * Run Addons
		 * Catches all add-on activations and deactivations and loads addons
		 * @since 0.1
		 * @version 1.2
		 */
		public function run_addons() {

			$installed = $this->get();

			// Make sure each active add-on still exists. If not delete.
			if ( ! empty( $this->active ) ) {
				$active = array_unique( $this->active );
				$_active = array();
				foreach ( $active as $pos => $active_id ) {
					if ( array_key_exists( $active_id, $installed ) ) {
						$_active[] = $active_id;
					}
				}
				$this->active = $_active;
			}

			// Load addons
			foreach ( $installed as $key => $data ) {
				if ( $this->is_active( $key ) ) {

					if ( apply_filters( 'mycred_run_addon', true, $key, $data, $this ) === false || apply_filters( 'mycred_run_addon_' . $key, true, $data, $this ) === false ) continue;

					// Core add-ons we know where they are
					if ( file_exists( myCRED_ADDONS_DIR . $key . '/myCRED-addon-' . $key . '.php' ) )
						include_once myCRED_ADDONS_DIR . $key . '/myCRED-addon-' . $key . '.php';

					// If path is set, load the file
					elseif ( isset( $data['path'] ) && file_exists( $data['path'] ) )
						include_once $data['path'];

					else {
						continue;
					}

					// Check for activation
					if ( $this->is_activation( $key ) )
						do_action( 'mycred_addon_activation_' . $key );

				}
			}

		}

		/**
		 * Is Activation
		 * @since 0.1
		 * @version 1.0
		 */
		public function is_activation( $key ) {

			if ( isset( $_GET['addon_action'] ) && isset( $_GET['addon_id'] ) && $_GET['addon_action'] == 'activate' && $_GET['addon_id'] == $key )
				return true;

			return false;

		}

		/**
		 * Is Deactivation
		 * @since 0.1
		 * @version 1.0
		 */
		public function is_deactivation( $key ) {

			if ( isset( $_GET['addon_action'] ) && isset( $_GET['addon_id'] ) && $_GET['addon_action'] == 'deactivate' && $_GET['addon_id'] == $key )
				return true;

			return false;

		}

		/**
		 * Get Addons
		 * @since 0.1
		 * @version 1.7.3
		 */
		public function get( $save = false ) {

			$installed = array();

			// Badges Add-on
			$installed['badges'] = array(
				'name'        => 'Badges',
				'description' => 'Give your users badges based on their interaction with your website.',
				'addon_url'   => 'http://codex.mycred.me/chapter-iii/badges/',
				'version'     => '1.3',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'screenshot'  => plugins_url( 'assets/images/badges-addon.png', myCRED_THIS ),
				'requires'    => array()
			);

			// buyCRED Add-on
			$installed['buy-creds'] = array(
				'name'        => 'buyCRED',
				'description' => 'The <strong>buy</strong>CRED Add-on allows your users to buy points using PayPal, Skrill (Moneybookers) or NETbilling. <strong>buy</strong>CRED can also let your users buy points for other members.',
				'addon_url'   => 'http://codex.mycred.me/chapter-iii/buycred/',
				'version'     => '1.5',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'screenshot'  => plugins_url( 'assets/images/buy-creds-addon.png', myCRED_THIS ),
				'requires'    => array()
			);
			
			// cashCRED Add-on
			$installed['cash-creds'] = array(	
				'name'        => 'cashCRED',
				'description' => 'cashCred allows your users to convert their Points into Cash and the possibility to withdraw their points through different payment gateways.',
				'addon_url'   => 'https://codex.mycred.me/chapter-iii/cashcred/',
				'version'     => '1.0',
				'author'      => 'Gabriel S Merovingi',
				'author_url'  => 'https://www.merovingi.com',
				'screenshot'  => plugins_url( 'assets/images/banking-addon.png', myCRED_THIS ),
				'requires'    => array()
			);

			// Central Deposit Add-on
			$installed['banking'] = array(
				'name'        => 'Central Deposit',
				'description' => 'Setup recurring payouts or offer / charge interest on user account balances.',
				'addon_url'   => 'https://codex.mycred.me/chapter-iii/central-deposit-add-on/',
				'version'     => '2.0',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'screenshot'  => plugins_url( 'assets/images/banking-addon.png', myCRED_THIS ),
				'requires'    => array()
			);

			// Coupons Add-on
			$installed['coupons'] = array(
				'name'        => 'Coupons',
				'description' => 'The coupons add-on allows you to create coupons that users can use to add points to their accounts.',
				'addon_url'   => 'http://codex.mycred.me/chapter-iii/coupons/',
				'version'     => '1.4',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'screenshot'  => plugins_url( 'assets/images/coupons-addon.png', myCRED_THIS ),
				'requires'    => array()
			);

			// Email Notices Add-on
			$installed['email-notices'] = array(
				'name'        => 'Email Notifications',
				'description' => 'Create email notices for any type of myCRED instance.',
				'addon_url'   => 'http://codex.mycred.me/chapter-iii/email-notice/',
				'version'     => '1.4',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'screenshot'  => plugins_url( 'assets/images/email-notifications-addon.png', myCRED_THIS ),
				'requires'    => array()
			);

			// Gateway Add-on
			$installed['gateway'] = array(
				'name'        => 'Gateway',
				'description' => 'Let your users pay using their <strong>my</strong>CRED points balance. Supported Carts: WooCommerce, MarketPress and WP E-Commerce. Supported Event Bookings: Event Espresso and Events Manager (free & pro).',
				'addon_url'   => 'http://codex.mycred.me/chapter-iii/gateway/',
				'version'     => '1.4',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'screenshot'  => plugins_url( 'assets/images/gateway-addon.png', myCRED_THIS ),
				'requires'    => array()
			);

			// Notifications Add-on
			$installed['notifications'] = array(
				'name'        => 'Notifications',
				'description' => 'Create pop-up notifications for when users gain or loose points.',
				'addon_url'   => 'http://codex.mycred.me/chapter-iii/notifications/',
				'version'     => '1.1.2',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'pro_url'     => 'https://mycred.me/store/notifications-plus-add-on/',
				'screenshot'  =>  plugins_url( 'assets/images/notifications-addon.png', myCRED_THIS ),
				'requires'    => array()
			);

			// Ranks Add-on
			$installed['ranks'] = array(
				'name'        => 'Ranks',
				'description' => 'Create ranks for users reaching a certain number of %_plural% with the option to add logos for each rank.',
				'addon_url'   => 'http://codex.mycred.me/chapter-iii/ranks/',
				'version'     => '1.6',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'screenshot'  => plugins_url( 'assets/images/ranks-addon.png', myCRED_THIS ),
				'requires'    => array()
			);

			// Sell Content Add-on
			$installed['sell-content'] = array(
				'name'        => 'Sell Content',
				'description' => 'This add-on allows you to sell posts, pages or any public post types on your website. You can either sell the entire content or using our shortcode, sell parts of your content allowing you to offer "teasers".',
				'addon_url'   => 'http://codex.mycred.me/chapter-iii/sell-content/',
				'version'     => '2.0.1',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'screenshot'  => plugins_url( 'assets/images/sell-content-addon.png', myCRED_THIS ),
				'requires'    => array( 'log' )
			);

			// Statistics Add-on
			$installed['stats'] = array(
				'name'        => 'Statistics',
				'description' => 'Gives you access to your myCRED Statistics based on your users gains and loses.',
				'addon_url'   => 'http://codex.mycred.me/chapter-iii/statistics/',
				'version'     => '2.0',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'screenshot'  => plugins_url( 'assets/images/statistics-addon.png', myCRED_THIS )
			);

			// Transfer Add-on
			$installed['transfer'] = array(
				'name'        => 'Transfers',
				'description' => 'Allow your users to send or "donate" points to other members by either using the mycred_transfer shortcode or the myCRED Transfer widget.',
				'addon_url'   => 'http://codex.mycred.me/chapter-iii/transfers/',
				'version'     => '1.6',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'pro_url'     => 'https://mycred.me/store/transfer-plus/',
				'screenshot'  => plugins_url( 'assets/images/transfer-addon.png', myCRED_THIS ),
				'requires'    => array()
			);

			//WooCommerce Add-on
            $installed['woocommerce'] = array(
                'name'        => 'WooCommerce',
                'description' => 'Allow your users to send or "donate" points to other members by either using the mycred_transfer shortcode or the myCRED Transfer widget.',
                'addon_url'   => 'http://codex.mycred.me',
                'version'     => '1.0',
                'author'      => 'myCred',
                'author_url'  => 'https://www.mycred.me',
                'pro_url'     => 'https://mycred.me/store',
                'screenshot'  => plugins_url( 'assets/images/transfer-addon.png', myCRED_THIS ),
                'requires'    => array()
            );

			// badge plus Add-on
			$installed['badge-plus'] = array(
				'name'        => 'Badge Plus',
				'description' => 'Allows you to create visual tokens and reward users with digital badges when they earn points.',
				'addon_url'   => 'https://codex.mycred.me/chapter-iii/freebies/mycred-badge-plus',
				'version'     => '1.0.0',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'pro_url'     => 'https://mycred.me/store/mycred-badge-plus/',
				'screenshot'  => plugins_url( 'assets/images/mycred-badge-plus.png', myCRED_THIS ),
				'requires'    => array()
			);

			// rank plus Add-on
			$installed['rank-plus'] = array(
				'name'        => 'Rank Plus',
				'description' => 'Allows the admin to add new rank types that will be awarded to their website users as rewards. This add-on is an enhanced version of the built-in Ranks add-on.',
				'addon_url'   => 'https://codex.mycred.me/chapter-iii/freebies/mycred-rank-plus',
				'version'     => '1.0.1',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'pro_url'     => 'https://mycred.me/store/mycred-rank-plus/',
				'screenshot'  => plugins_url( 'assets/images/mycred-rank-plus.png', myCRED_THIS ),
				'requires'    => array()
			);

			// badge editor Add-on
			$installed['badge-editor'] = array(
				'name'        => 'Badge Editor',
				'description' => 'Allows you to design, edit and download professional-looking digital badge images from the plugin’s back-end dashboard.',
				'addon_url'   => 'https://codex.mycred.me/chapter-iii/freebies/mycred-badge-editor',
				'version'     => '1.0',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'pro_url'     => 'https://mycred.me/store/mycred-badge-editor/',
				'screenshot'  => plugins_url( 'assets/images/mycred-badge-editor.jpg', myCRED_THIS ),
				'requires'    => array()
			);

			// birthdays Add-on
			$installed['birthday'] = array(
				'name'        => 'Birthday',
				'description' => 'Gives you access to the myCred Birthday hook which you can setup to reward / deduct points from your users on their birthday!',
				'addon_url'   => 'https://codex.mycred.me/hooks/birthdays/',
				'version'     => '1.0',
				'author'      => 'myCred',
				'author_url'  => 'https://www.mycred.me',
				'pro_url'     => 'https://mycred.me/store/mycred-birthdays/',
				'screenshot'  => plugins_url( 'assets/images/myCred-Birthdays.png', myCRED_THIS ),
				'requires'    => array()
			);

			$installed = apply_filters( 'mycred_setup_addons', $installed );

			if ( $save === true && $this->core->user_is_point_admin() ) {
				$new_data = array(
					'active'    => $this->active,
					'installed' => $installed
				);
				mycred_update_option( 'mycred_pref_addons', $new_data );
			}

			$this->installed = $installed;
			
			return $installed;

		}

		/**
		 * Admin Page
		 * @since 0.1
		 * @version 1.2.2
		 */
		public function admin_page() {

			wp_enqueue_script('wp-element');
			wp_enqueue_script( 'mycred-builtin-addons-script' );

			echo '<div id="mycred-builtin-addons" style="margin-left:-20px"></div>';

			// Security
			if ( ! $this->core->user_is_point_admin() ) wp_die( 'Access Denied' );
			
		}

		/**
		 * Activate / Deactivate Button
		 * @since 0.1
		 * @version 1.2
		 */
		public function activate_deactivate( $addon_id = NULL ) {

			$link_url  = get_mycred_addon_activation_url( $addon_id );
			$link_text = __( 'Activate', 'mycred' );

			// Deactivate
			if ( $this->is_active( $addon_id ) ) {

				$link_url  = get_mycred_addon_deactivation_url( $addon_id );
				$link_text = __( 'Deactivate', 'mycred' );

			}

			return '<a href="' . esc_url_raw( $link_url ) . '" title="' . esc_attr( $link_text ) . '" class="mycred-action ' . esc_attr( $addon_id ) . '">' . esc_html( $link_text ) . '</a>';

		}

		public function check_all_addons( ) {
		
			$all_addons = count($this->installed);
			$active_addons = count($this->active);
			
			if($all_addons == $active_addons){
				
				return true;

			}else{

				return false;
			}
		}
	}
endif;

/**
 * Get Activate Add-on Link
 * @since 1.7
 * @version 1.0
 */
if ( ! function_exists( 'get_mycred_addon_activation_url' ) ) :
	function get_mycred_addon_activation_url( $addon_id = NULL, $deactivate = false ) {

		if ( $addon_id === NULL ) return '#';

		$args = array(
			'page'         => MYCRED_SLUG . '-addons',
			'addon_id'     => $addon_id,
			'addon_action' => ( ( $deactivate === false ) ? 'activate' : 'deactivate' ),
			'_token'       => wp_create_nonce( 'mycred-activate-deactivate-addon' )
		);

		return esc_url( add_query_arg( $args, admin_url( 'admin.php' ) ) );

	}
endif;

/**
 * Get Deactivate Add-on Link
 * @since 1.7
 * @version 1.0
 */
if ( ! function_exists( 'get_mycred_addon_deactivation_url' ) ) :
	function get_mycred_addon_deactivation_url( $addon_id = NULL ) {

		if ( $addon_id === NULL ) return '#';

		return get_mycred_addon_activation_url( $addon_id, true );

	}
endif;




if ( ! function_exists( 'get_mycred_all_addon_activation_url' ) ) :
	function get_mycred_all_addon_activation_url() 
  {

		$args = array(
			'page'         => MYCRED_SLUG . '-addons',
			'addon_all_action' =>  'activate',
			'_token'       => wp_create_nonce( 'mycred-activate-deactivate-addon' )
		);

		return esc_url( add_query_arg( $args, admin_url( 'admin.php' ) ) );

	}
endif;


if ( ! function_exists( 'get_mycred_all_addon_deactivation_url' ) ) :
	function get_mycred_all_addon_deactivation_url( ) {
		
		$args = array(
			'page'         => MYCRED_SLUG . '-addons',
			'addon_all_action' =>  'deactivate',
			'_token'       => wp_create_nonce( 'mycred-activate-deactivate-addon' )
		);

		return esc_url( add_query_arg( $args, admin_url( 'admin.php' ) ) );

	}
endif;

if ( ! function_exists( 'get_mycred_addon_page_url' ) ) :
	function get_mycred_addon_page_url( $addon_type ) {
		
		$args = array(
			'page'         => MYCRED_SLUG . '-addons',
			'mycred_addons' =>  $addon_type,
		);

		return esc_url( add_query_arg( $args, admin_url( 'admin.php' ) ) );

	}
endif;
