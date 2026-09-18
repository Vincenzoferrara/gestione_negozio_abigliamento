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
			
			// Register REST API routes for addons management
			add_action( 'rest_api_init', array( $this, 'register_addons_rest_routes' ) );
			add_action( 'admin_menu', array( $this, 'remove_mycred_toolkit_submenu_conditionally' ), 999 );
			add_action( 'admin_init', array( $this, 'redirect_legacy_toolkit_admin_page' ) );


		}

		/**
		 * Hide legacy Toolkit submenu when core uses unified add-ons.
		 */
		public function remove_mycred_toolkit_submenu_conditionally() {

			if ( ! function_exists( 'mycred_addons_is_unified' ) || ! mycred_addons_is_unified() ) {
				return;
			}

			$parent_slug = defined( 'MYCRED_MAIN_SLUG' ) ? MYCRED_MAIN_SLUG : 'mycred-main';

			remove_submenu_page( $parent_slug, 'mycred-toolkit' );
			remove_submenu_page( $parent_slug, 'mycred-toolkit-pro' );
		}

		/**
		 * Redirect bookmarked legacy Toolkit URLs to unified Add-ons.
		 */
		public function redirect_legacy_toolkit_admin_page() {

			if ( ! is_admin() || ! function_exists( 'mycred_addons_is_unified' ) || ! mycred_addons_is_unified() ) {
				return;
			}

			// phpcs:ignore WordPress.Security.NonceVerification.Recommended
			$page = isset( $_GET['page'] ) ? sanitize_text_field( wp_unslash( $_GET['page'] ) ) : '';

			if ( ! in_array( $page, array( 'mycred-toolkit', 'mycred-toolkit-pro' ), true ) ) {
				return;
			}

			$addons_slug = defined( 'MYCRED_SLUG' ) ? MYCRED_SLUG . '-addons' : 'mycred-addons';

			wp_safe_redirect( admin_url( 'admin.php?page=' . $addons_slug ) );
			exit;
		}
		/**
		 * Register REST routes (moved from core for better cohesion)
		 */
		public function register_addons_rest_routes() {
			register_rest_route( 'mycred/v1', '/enable-core-addon', array(
				'methods'  => 'POST',
				'callback' => array( $this, 'rest_enable_core_addon' ),
				'permission_callback' => array( $this, 'rest_verify_permissions' )
			) );

			register_rest_route( 'mycred/v1', '/get-core-addons', array(
				'methods'  => 'GET',
				'callback' => array( $this, 'rest_get_core_addons' ),
				'permission_callback' => array( $this, 'rest_verify_permissions' )
			) );

			register_rest_route( 'mycred/v1', '/install-toolkit', array(
				'methods'  => 'POST',
				'callback' => array( $this, 'rest_install_toolkit' ),
				'permission_callback' => array( $this, 'rest_verify_permissions' )
			) );
		}

		/**
		 * Permissions & nonce verification
		 */
		public function rest_verify_permissions( $request ) {
			$nonce = $request->get_header( 'X-WP-Nonce' );
			if ( ! $nonce ) {
				return new WP_Error( 'rest_missing_nonce', __( 'Missing nonce.', 'mycred' ), array( 'status' => 403 ) );
			}
			if ( ! wp_verify_nonce( $nonce, 'wp_rest' ) ) {
				return new WP_Error( 'rest_invalid_nonce', __( 'Invalid nonce.', 'mycred' ), array( 'status' => 403 ) );
			}
			if ( ! current_user_can( 'manage_options' ) ) {
				return new WP_Error( 'rest_forbidden', __( 'You do not have permission to perform this action.', 'mycred' ), array( 'status' => 403 ) );
			}
			return true;
		}

		/**
		 * Get active core addons
		 */
		public function rest_get_core_addons( $request ) {
			$addons = function_exists( 'mycred_get_stored_addon_slugs' )
				? mycred_get_stored_addon_slugs()
				: ( function_exists( 'mycred_get_active_addon_slugs' ) ? mycred_get_active_addon_slugs() : array() );

			return rest_ensure_response( $addons );
		}

		/**
		 * Toggle a core addon
		 */
		private function get_addons_catalog() {
			static $catalog = null;

			if ( is_array( $catalog ) ) {
				return $catalog;
			}

			$catalog_path = myCRED_ADDONS_DIR . 'src/admin/addons.json';
			if ( ! file_exists( $catalog_path ) ) {
				$catalog = array();
				return $catalog;
			}

			$raw = file_get_contents( $catalog_path );
			if ( ! is_string( $raw ) || $raw === '' ) {
				$catalog = array();
				return $catalog;
			}

			$decoded = json_decode( $raw, true );
			$catalog = is_array( $decoded ) ? $decoded : array();

			return $catalog;
		}

		private function validate_addon_dependency( $slug, $title = '', $dependency = '', $dependency_name = '' ) {
			$slug = sanitize_text_field( $slug );

			if ( $dependency === '' ) {
				foreach ( $this->get_addons_catalog() as $addon ) {
					if ( empty( $addon['slug'] ) || $addon['slug'] !== $slug ) {
						continue;
					}

					$dependency      = isset( $addon['dependency'] ) ? sanitize_text_field( $addon['dependency'] ) : '';
					$dependency_name = isset( $addon['dependencyName'] ) ? sanitize_text_field( $addon['dependencyName'] ) : '';
					break;
				}
			}

			if ( empty( $dependency ) || $dependency === 'mycred/mycred.php' ) {
				return true;
			}

			if ( ! function_exists( 'is_plugin_active' ) ) {
				require_once ABSPATH . 'wp-admin/includes/plugin.php';
			}

			if ( is_plugin_active( $dependency ) ) {
				return true;
			}

			$resolved_title = $title !== '' ? $title : $slug;
			$resolved_dep   = $dependency_name !== '' ? $dependency_name : $dependency;

			return new WP_Error(
				'dependency_missing',
				sprintf(
					__( 'Add-on "%s" requires the "%s" plugin to be active. Please activate it first.', 'mycred' ),
					$resolved_title,
					$resolved_dep
				)
			);
		}

		public function rest_enable_core_addon( $request ) {
			$params = $request->get_json_params();
			$slug  = isset( $params['addOnSlug'] ) ? sanitize_text_field( $params['addOnSlug'] ) : '';
			$title = isset( $params['addOnTitle'] ) ? sanitize_text_field( $params['addOnTitle'] ) : '';
			$source = isset( $params['source'] ) ? sanitize_text_field( $params['source'] ) : 'core';
			$dependency = isset( $params['dependency'] ) ? sanitize_text_field( $params['dependency'] ) : '';
			$dependencyName = isset( $params['dependencyName'] ) ? sanitize_text_field( $params['dependencyName'] ) : '';

			$dependency_status = $this->validate_addon_dependency( $slug, $title, $dependency, $dependencyName );
			if ( is_wp_error( $dependency_status ) ) {
				return rest_ensure_response( array(
					'status'  => 'error',
					'code'    => $dependency_status->get_error_code(),
					'message' => $dependency_status->get_error_message(),
				) );
			}

			if ( function_exists( 'mycred_set_addon_active' ) ) {
				$prefs     = get_option( 'mycred_pref_addons', array( 'active' => array() ) );
				$is_active = is_array( $prefs['active'] ) && in_array( $slug, $prefs['active'], true );

				if ( ! $is_active && function_exists( 'mycred_can_enable_toolkit_addon' ) ) {
					$can_enable = mycred_can_enable_toolkit_addon( $slug, $source );

					if ( is_wp_error( $can_enable ) ) {
						return rest_ensure_response( array(
							'status'  => 'error',
							'code'    => $can_enable->get_error_code(),
							'message' => sprintf(
								__( 'Add-on "%s" could not be enabled. File does not exist or is not included in your plan.', 'mycred' ),
								$title
							),
						) );
					}
				}

				$result = mycred_set_addon_active( $slug );
				$toggle = ! empty( $result['toggle'] );
			} else {
				$result  = array( 'success' => false, 'toggle' => false );
				$toggle  = false;
			}

			if ( empty( $result['success'] ) ) {
				return rest_ensure_response( array(
					'status'  => 'error',
					'message' => sprintf( __( 'Add-on "%s" could not be updated.', 'mycred' ), $title ),
				) );
			}

			$message = $toggle
				? sprintf( __( 'Add-on "%s" has been enabled successfully.', 'mycred' ), $title )
				: sprintf( __( 'Add-on "%s" has been disabled successfully.', 'mycred' ), $title );

			return rest_ensure_response( array(
				'status'        => 'success',
				'message'       => $message,
				'enabled_addon' => $slug,
				'toggle'        => $toggle,
			) );
		}

		/**
		 * Install & activate mycred-toolkit plugin
		 */
		public function rest_install_toolkit( $request ) {
			
			$params = $request->get_json_params();
			$addon_slug = isset( $params['addon_slug'] ) ? sanitize_text_field( $params['addon_slug'] ) : '';

			if ( ! function_exists( 'is_plugin_active' ) ) {
				require_once ABSPATH . 'wp-admin/includes/plugin.php';
			}
			
			$activated = false;
			$message = '';

			// Already active
			if ( function_exists( 'mycred_is_toolkit_plugin_active' ) && mycred_is_toolkit_plugin_active() ) {
				$activated = true;
				$message = __( 'myCred Addons package is already active.', 'mycred' );
			}
			// Activate if installed
			elseif ( function_exists( 'mycred_is_toolkit_plugin_installed' ) && mycred_is_toolkit_plugin_installed() ) {
				$plugin_file = '';
				foreach ( array_keys( get_plugins() ) as $candidate ) {
					if ( 'mycred-toolkit.php' === basename( $candidate ) ) {
						$plugin_file = $candidate;
						break;
					}
				}

				if ( empty( $plugin_file ) ) {
					return new WP_Error( 'plugin_file_missing', __( 'Plugin installed but main file not found. Please try again or install manually.', 'mycred' ), array( 'status' => 500 ) );
				}

				$activation = activate_plugin( $plugin_file );
				if ( is_wp_error( $activation ) ) {
					return new WP_Error( 'activation_failed', $activation->get_error_message(), array( 'status' => 500 ) );
				}
				$activated = true;
				$message = __( 'myCred Addons package activated successfully.', 'mycred' );
			}
			// Install from WP.org
			else {
				require_once ABSPATH . 'wp-admin/includes/class-wp-upgrader.php';
				require_once ABSPATH . 'wp-admin/includes/plugin-install.php';
				require_once ABSPATH . 'wp-admin/includes/plugin.php';
				require_once ABSPATH . 'wp-admin/includes/file.php';
				require_once ABSPATH . 'wp-admin/includes/misc.php';
	
				$api = plugins_api( 'plugin_information', array( 'slug' => 'mycred-toolkit', 'fields' => array( 'sections' => false ) ) );
				if ( is_wp_error( $api ) ) {
					return new WP_Error( 'install_api_error', $api->get_error_message(), array( 'status' => 500 ) );
				}
				
				$skin = new Automatic_Upgrader_Skin();
				$upgrader = new Plugin_Upgrader( $skin );
				$result = $upgrader->install( $api->download_link );
			
				if ( is_wp_error( $result ) ) {
					return new WP_Error( 'install_failed', $result->get_error_message(), array( 'status' => 500 ) );
				}
				
				$plugin_file = 'mycred-toolkit/mycred-toolkit.php'; // Standard path
				
				if ( ! file_exists( WP_PLUGIN_DIR . '/' . $plugin_file ) ) {
					return new WP_Error( 'plugin_file_missing', __( 'Plugin installed but main file not found. Please try again or install manually.', 'mycred' ), array( 'status' => 500 ) );
				}

				$activation = activate_plugin( $plugin_file );
				if ( is_wp_error( $activation ) ) {
					return new WP_Error( 'activation_failed', $activation->get_error_message(), array( 'status' => 500 ) );
				}
				
				$activated = true;
				$message = __( 'myCred Addons package installed and activated successfully.', 'mycred' );
			}

			// Activate specific addon if requested
			$addon_activated = false;
			$addon_error_message = '';
			$addon_error_code = '';
			if ( $activated && ! empty( $addon_slug ) && function_exists( 'mycred_set_addon_active' ) ) {
				$dependency_status = $this->validate_addon_dependency( $addon_slug, $addon_slug );

				if ( is_wp_error( $dependency_status ) ) {
					$addon_error_code    = $dependency_status->get_error_code();
					$addon_error_message = $dependency_status->get_error_message();
					$message            .= ' ' . $addon_error_message;
				} else {
					$enable_result = mycred_set_addon_active( $addon_slug, true );
					if ( ! empty( $enable_result['success'] ) && ! empty( $enable_result['toggle'] ) ) {
						$addon_activated = true;
						$message        .= ' ' . sprintf( __( 'Addon "%s" activated.', 'mycred' ), $addon_slug );
					}
				}
			}

			return rest_ensure_response( array(
				'status'          => 'success',
				'message'         => $message,
				'activated'       => true,
				'addon_activated' => $addon_activated,
				'addon_slug'      => $addon_slug,
				'addon_error_code' => $addon_error_code,
				'addon_error_message' => $addon_error_message,
			) );
		}

		/**
		 * Admin Init
		 * Catch activation and deactivations
		 * @since 0.1
		 * @version 1.2.2
		 */
		public function module_admin_init() {

			add_action( 'admin_enqueue_scripts', array( $this, 'mycred_addons_scripts' ) );
			add_filter( 'admin_body_class', array( $this, 'add_addons_body_class' ) );
			// Handle actions

			$this->all_activate_deactivate();

			if ( function_exists( 'mycred_maybe_migrate_addons_schema' ) ) {
				mycred_maybe_migrate_addons_schema();
			}

		}

		public function add_addons_body_class( $classes ) {

			$screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;

			if ( ! $screen ) {
				return $classes;
			}

			$addons_slug = defined( 'MYCRED_SLUG' ) ? MYCRED_SLUG . '-addons' : 'mycred-addons';

			if ( strpos( $screen->id, $addons_slug ) === false ) {
				return $classes;
			}

			return $classes . ' mycred-addons-admin-page';
		}

		public function mycred_addons_scripts( $hook = '' ) {

			$addons_slug = defined( 'MYCRED_SLUG' ) ? MYCRED_SLUG . '-addons' : 'mycred-addons';

			if ( $hook === '' || strpos( $hook, $addons_slug ) === false ) {
				return;
			}

			$asset_file = myCRED_ADDONS_DIR . 'build/admin.bundle.asset.php';
			$asset      = file_exists( $asset_file ) ? include $asset_file : array(
				'dependencies' => array( 'wp-element', 'wp-i18n' ),
				'version'      => '1.0.0',
			);

			wp_register_style(
				'mycred-addons-style',
				plugins_url( 'addons/build/admin.css', myCRED_THIS ),
				array(),
				$asset['version']
			);
			wp_enqueue_style( 'mycred-addons-style' );

			wp_add_inline_style(
				'mycred-addons-style',
				'#mycred-addons{background:#fafafc}'
				. 'body.mycred-addons-admin-page #myCRED-wrap>h1{display:none}'
				. '#mycred-addons .mycred-addons-section{container-type:inline-size;container-name:addons-section}'
				. '#mycred-addons .mycred-addons-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}'
				. '@container addons-section (min-width:640px){#mycred-addons .mycred-addons-grid{grid-template-columns:repeat(4,minmax(0,1fr))}}'
				. '@container addons-section (min-width:1400px){#mycred-addons .mycred-addons-grid{grid-template-columns:repeat(5,minmax(0,1fr))}}'
				. '#mycred-addons .mycred-addons-card{background:#fff;border:1px solid #e9e4f6;border-radius:8px;padding:16px 16px 0}'
				. '#mycred-addons .mycred-addons-skeleton{background:#eee;border-radius:6px}'
			);

			wp_register_script(
				'mycred-addons-script',
				plugins_url( 'addons/build/admin.bundle.js', myCRED_THIS ),
				$asset['dependencies'],
				$asset['version'],
				true
			);

			// Detect toolkit & toolkit pro plugins so React can decide install buttons.
			$toolkit_active     = function_exists( 'mycred_is_toolkit_plugin_active' ) ? mycred_is_toolkit_plugin_active() : class_exists( 'MyCRED_Toolkit_Core' );
			$toolkit_pro_active = function_exists( 'mycred_is_toolkit_pro_plugin_active' ) ? mycred_is_toolkit_pro_plugin_active() : class_exists( 'MyCRED_Toolkit_Core_Pro' );
			$toolkit_installed  = function_exists( 'mycred_is_toolkit_plugin_installed' ) ? mycred_is_toolkit_plugin_installed() : $toolkit_active;

			$schema = function_exists( 'mycred_addons_schema' ) ? mycred_addons_schema() : array();

			$active_slugs = array();
			if ( function_exists( 'mycred_get_stored_addon_slugs' ) ) {
				$active_slugs = mycred_get_stored_addon_slugs();
			} elseif ( function_exists( 'mycred_get_active_addon_slugs' ) ) {
				$active_slugs = mycred_get_active_addon_slugs();
			}

			wp_localize_script( 'mycred-addons-script', 'mycredAddonsData', array(
				'upgraded'            => apply_filters( 'mycred_plan_check', true ),
				'root'                => esc_url_raw( rest_url() ),
				'nonce'               => wp_create_nonce( 'wp_rest' ),
				'toolkitActive'       => (bool) $toolkit_active,
				'toolkitInstalled'    => (bool) $toolkit_installed,
				'toolkitProActive'    => (bool) $toolkit_pro_active,
				'addonsDualWrite'     => function_exists( 'mycred_addons_dual_write_enabled' ) ? mycred_addons_dual_write_enabled() : false,
				'addonsUnified'       => function_exists( 'mycred_addons_is_unified' ) ? mycred_addons_is_unified() : false,
				'addonsSchemaVersion' => isset( $schema['version'] ) ? (int) $schema['version'] : 1,
				'activeSlugs'         => array_values( $active_slugs ),
				'userPlan'            => apply_filters( 'mycred_addons_user_plan', 'free' ),
			) );

			wp_enqueue_script( 'mycred-addons-script' );

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

			// Make sure each active built-in add-on still exists. If not delete.
			if ( ! empty( $this->active ) ) {
				// Sanitize: Ensure we only have valid slugs (strings/ints)
				$this->active = array_filter( $this->active, function( $item ) {
					return is_string( $item ) || is_int( $item );
				} );

				$unified = function_exists( 'mycred_addons_is_unified' ) && mycred_addons_is_unified();

				if ( ! $unified ) {
					$active  = array_unique( $this->active );
					$_active = array();
					foreach ( $active as $pos => $active_id ) {
						if ( array_key_exists( $active_id, $installed ) ) {
							$_active[] = $active_id;
						}
					}
					$this->active = $_active;
				}
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
		 * Boot placeholder shown before React mounts (avoids empty flash).
		 */
		private function render_addons_boot_placeholder() {
			?>
			<div class="mycred-addons-wrap mycred-addons-boot" aria-hidden="true">
				<div class="mycred-addons-shell">
					<div class="mycred-addons-boot-header">
						<div class="mycred-addons-skeleton"></div>
						<div class="mycred-addons-skeleton" style="height:14px;width:280px;margin-top:12px"></div>
						<div class="mycred-addons-boot-controls">
							<div class="mycred-addons-skeleton" style="height:40px;width:320px;border-radius:8px"></div>
							<div class="mycred-addons-skeleton" style="height:40px;width:86px;border-radius:8px"></div>
						</div>
					</div>
					<div class="mycred-addons-shell-body">
						<div class="mycred-addons-skeleton" style="height:32px;width:100%;border-radius:4px;margin-bottom:18px"></div>
						<section class="mycred-addons-section">
							<div class="mycred-addons-grid">
								<?php for ( $i = 0; $i < 8; $i++ ) : ?>
								<article class="mycred-addons-card">
									<div class="mycred-addons-card-top">
										<div class="mycred-addons-icon mycred-addons-skeleton" style="width:48px;height:48px;border-radius:50%"></div>
									</div>
									<div class="mycred-addons-skeleton" style="height:16px;margin-top:12px;width:70%"></div>
									<div class="mycred-addons-skeleton" style="height:36px;margin-top:8px"></div>
									<div class="mycred-addons-card-foot">
										<div class="mycred-addons-skeleton" style="height:14px;width:60px"></div>
									</div>
								</article>
								<?php endfor; ?>
							</div>
						</section>
					</div>
				</div>
			</div>
			<?php
		}

		/**
		 * Admin Page
		 * @since 0.1
		 * @version 1.2.2
		 */
		public function admin_page() {

			// Security
			if ( ! $this->core->user_is_point_admin() ) {
				wp_die( 'Access Denied' );
			}

			wp_enqueue_script( 'mycred-addons-script' );

			if ( function_exists( 'mycred_render_admin_header' ) ) {
				mycred_render_admin_header();
			}

			echo '<div class="wrap mycred-metabox" id="myCRED-wrap">';
			echo '<div id="mycred-addons">';
			$this->render_addons_boot_placeholder();
			echo '</div>';
			echo '</div>';
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
