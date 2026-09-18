<?php
/**
 * Unified add-ons registry: schema, read/write helpers, and migration.
 *
 * @package myCred
 */

if ( ! defined( 'myCRED_VERSION' ) ) {
	exit;
}

if ( ! defined( 'MYCRED_ADDONS_SCHEMA_OPTION' ) ) {
	define( 'MYCRED_ADDONS_SCHEMA_OPTION', 'mycred_addons_schema' );
}

if ( ! function_exists( 'mycred_addons_schema' ) ) :
	/**
	 * Get the add-ons schema option.
	 *
	 * @return array
	 */
	function mycred_addons_schema() {
		$schema = get_option( MYCRED_ADDONS_SCHEMA_OPTION, array() );

		if ( ! is_array( $schema ) ) {
			$schema = array();
		}

		if ( ! isset( $schema['version'] ) ) {
			$schema['version'] = 1;
		}

		return $schema;
	}
endif;

if ( ! function_exists( 'mycred_addons_is_unified' ) ) :
	/**
	 * Whether unified add-ons storage is active.
	 *
	 * @return bool
	 */
	function mycred_addons_is_unified() {
		if ( ! defined( 'MYCRED_ADDONS_UNIFIED_UI' ) || ! MYCRED_ADDONS_UNIFIED_UI ) {
			return false;
		}

		$schema = mycred_addons_schema();

		return isset( $schema['version'] ) && (int) $schema['version'] >= 2;
	}
endif;

if ( ! function_exists( 'mycred_toolkit_supports_unified' ) ) :
	/**
	 * Whether an active toolkit build declares unified add-on support.
	 *
	 * @return bool
	 */
	function mycred_toolkit_supports_unified() {
		return defined( 'MYCRED_TOOLKIT_UNIFIED_ADDONS' ) && MYCRED_TOOLKIT_UNIFIED_ADDONS;
	}
endif;

if ( ! function_exists( 'mycred_is_core_plugin_active' ) ) :
	/**
	 * Whether myCred core is active (production or dev plugin path).
	 *
	 * @return bool
	 */
	function mycred_is_core_plugin_active() {
		return class_exists( 'myCRED_Core' ) || defined( 'myCRED_VERSION' );
	}
endif;

if ( ! function_exists( 'mycred_is_toolkit_plugin_active' ) ) :
	/**
	 * Whether myCred Toolkit is active (production or dev build).
	 *
	 * @return bool
	 */
	function mycred_is_toolkit_plugin_active() {
		return class_exists( 'MyCRED_Toolkit_Core' );
	}
endif;

if ( ! function_exists( 'mycred_is_toolkit_pro_plugin_active' ) ) :
	/**
	 * Whether myCred Toolkit Pro is active (production or dev build).
	 *
	 * @return bool
	 */
	function mycred_is_toolkit_pro_plugin_active() {
		return class_exists( 'MyCRED_Toolkit_Core_Pro' );
	}
endif;

if ( ! function_exists( 'mycred_is_toolkit_plugin_installed' ) ) :
	/**
	 * Whether myCred Toolkit is installed (active or inactive, any plugin folder).
	 *
	 * @return bool
	 */
	function mycred_is_toolkit_plugin_installed() {
		if ( mycred_is_toolkit_plugin_active() ) {
			return true;
		}

		if ( ! function_exists( 'get_plugins' ) ) {
			require_once ABSPATH . 'wp-admin/includes/plugin.php';
		}

		foreach ( array_keys( get_plugins() ) as $plugin_file ) {
			if ( 'mycred-toolkit.php' === basename( $plugin_file ) ) {
				return true;
			}
		}

		return false;
	}
endif;

if ( ! function_exists( 'mycred_addons_dual_write_enabled' ) ) :
	/**
	 * Whether legacy mycred_enabled_addons should stay in sync.
	 *
	 * @return bool
	 */
	function mycred_addons_dual_write_enabled() {
		if ( ! mycred_addons_is_unified() ) {
			return false;
		}

		$schema = mycred_addons_schema();

		return ! empty( $schema['dual_write'] );
	}
endif;

if ( ! function_exists( 'mycred_sync_legacy_enabled_addons' ) ) :
	/**
	 * Mirror active slugs to the legacy toolkit option.
	 *
	 * @param array $active_slugs Active add-on slugs.
	 */
	function mycred_sync_legacy_enabled_addons( $active_slugs ) {
		if ( ! is_array( $active_slugs ) ) {
			$active_slugs = array();
		}

		$active_slugs = array_values( array_unique( array_filter( $active_slugs, 'mycred_addons_is_valid_slug' ) ) );

		update_option( 'mycred_enabled_addons', $active_slugs );
	}
endif;

if ( ! function_exists( 'mycred_addons_is_valid_slug' ) ) :
	/**
	 * @param mixed $slug Slug candidate.
	 * @return bool
	 */
	function mycred_addons_is_valid_slug( $slug ) {
		return is_string( $slug ) && $slug !== '';
	}
endif;

if ( ! function_exists( 'mycred_toolkit_addon_file_exists' ) ) :
	/**
	 * Whether a toolkit add-on bootstrap file exists on disk.
	 *
	 * @param string $slug Add-on slug.
	 * @return bool
	 */
	function mycred_toolkit_addon_file_exists( $slug ) {
		if ( ! mycred_addons_is_valid_slug( $slug ) ) {
			return false;
		}

		if ( defined( 'MYCRED_TOOLKIT_ROOT_DIR_PRO' ) ) {
			$pro_path = MYCRED_TOOLKIT_ROOT_DIR_PRO . 'includes/addons/' . $slug . '/' . $slug . '.php';
			if ( file_exists( $pro_path ) ) {
				return true;
			}
		}

		if ( defined( 'MYCRED_TOOLKIT_ROOT_DIR' ) ) {
			$free_path = MYCRED_TOOLKIT_ROOT_DIR . 'includes/addons/' . $slug . '/' . $slug . '.php';
			if ( file_exists( $free_path ) ) {
				return true;
			}
		}

		return false;
	}
endif;

if ( ! function_exists( 'mycred_can_enable_toolkit_addon' ) ) :
	/**
	 * Whether a toolkit add-on may be enabled (file must exist).
	 *
	 * @param string $slug   Add-on slug.
	 * @param string $source Add-on source (core|toolkit).
	 * @return true|WP_Error
	 */
	function mycred_can_enable_toolkit_addon( $slug, $source = 'core' ) {
		if ( $source !== 'toolkit' ) {
			return true;
		}

		if ( mycred_toolkit_addon_file_exists( $slug ) ) {
			return true;
		}

		return new WP_Error(
			'addon_locked',
			__( 'This add-on is not available in your current plan or could not be found.', 'mycred' )
		);
	}
endif;

if ( ! function_exists( 'mycred_get_child_addon_map' ) ) :
	/**
	 * Parent add-on slug => implicit Toolkit Pro child slugs (unified UI).
	 *
	 * @return array
	 */
	function mycred_get_child_addon_map() {
		$map = array(
			'transfer'      => array( 'mycred-transfer-plus' ),
			'coupons'       => array( 'mycred-coupons-plus' ),
			'email-notices' => array( 'mycred-email-plus' ),
			'woocommerce'   => array( 'mycred-woocommerce-plus' ),
			'birthday'      => array( 'mycred-birthday-plus' ),
			'buy-creds'     => array(
				'mycred-paystack',
				'mycred-robokassa',
				'mycred-coinpayment',
				'mycred-paymentwall',
				'mycred-2co',
				'mycred-coinbase',
				'mycred-wepay',
				'mycred-stripe',
				'mycred-payfast',
			),
			'cash-creds'    => array(
				'mycred-cashcred-paystack',
				'mycred-cashcred-stripe',
				'mycred-cashcred-paypal',
			),
		);

		/**
		 * Filter the parent => child add-on slug map.
		 *
		 * @param array $map Parent slug => child slug list.
		 */
		return apply_filters( 'mycred_child_addon_map', $map );
	}
endif;

if ( ! function_exists( 'mycred_get_all_child_addon_slugs' ) ) :
	/**
	 * Flat list of child add-on slugs hidden from the unified Add-ons page.
	 *
	 * @return array
	 */
	function mycred_get_all_child_addon_slugs() {
		$slugs = array();

		foreach ( mycred_get_child_addon_map() as $children ) {
			if ( is_array( $children ) ) {
				$slugs = array_merge( $slugs, $children );
			}
		}

		return array_values( array_unique( array_filter( $slugs, 'mycred_addons_is_valid_slug' ) ) );
	}
endif;

if ( ! function_exists( 'mycred_is_child_addon' ) ) :
	/**
	 * Whether a slug is an implicit child add-on.
	 *
	 * @param string $slug Add-on slug.
	 * @return bool
	 */
	function mycred_is_child_addon( $slug ) {
		return in_array( $slug, mycred_get_all_child_addon_slugs(), true );
	}
endif;

if ( ! function_exists( 'mycred_get_child_addon_parent' ) ) :
	/**
	 * Parent slug for a child add-on, if any.
	 *
	 * @param string $slug Child add-on slug.
	 * @return string|false
	 */
	function mycred_get_child_addon_parent( $slug ) {
		foreach ( mycred_get_child_addon_map() as $parent => $children ) {
			if ( is_array( $children ) && in_array( $slug, $children, true ) ) {
				return $parent;
			}
		}

		return false;
	}
endif;

if ( ! function_exists( 'mycred_child_addon_is_active' ) ) :
	/**
	 * Whether a child add-on slug is expanded and active.
	 *
	 * @param string $slug Child add-on slug.
	 * @return bool
	 */
	function mycred_child_addon_is_active( $slug ) {
		if ( ! mycred_addons_is_valid_slug( $slug ) ) {
			return false;
		}

		return in_array( $slug, mycred_get_active_addon_slugs(), true );
	}
endif;

if ( ! function_exists( 'mycred_should_show_child_addon_upsell' ) ) :
	/**
	 * Whether to show a Paid / upgrade prompt for a child add-on.
	 *
	 * @param string $slug Child add-on slug.
	 * @return bool
	 */
	function mycred_should_show_child_addon_upsell( $slug ) {
		if ( ! defined( 'MYCRED_SHOW_PREMIUM_ADDONS' ) || ! MYCRED_SHOW_PREMIUM_ADDONS ) {
			return false;
		}

		return ! mycred_child_addon_is_active( $slug );
	}
endif;

if ( ! function_exists( 'mycred_get_gateway_upsell_catalog' ) ) :
	/**
	 * Catalog of premium payment gateway upsell rows.
	 *
	 * @param string $type buycred|cashcred
	 * @return array
	 */
	function mycred_get_gateway_upsell_catalog( $type ) {
		$catalog = array();

		if ( $type === 'buycred' ) {
			$catalog = array(
				array(
					'slug'         => 'mycred-paystack',
					'text'         => 'Paystack',
					'url'          => 'https://mycred.me/store/buycred-paystack/',
					'gateway_keys' => array( 'mycred_paystack' ),
					'plugin'       => 'mycred-paystack/mycred-paystack.php',
				),
				array(
					'slug'         => 'mycred-robokassa',
					'text'         => 'Robokassa',
					'url'          => 'https://mycred.me/store/buycred-robokassa/',
					'gateway_keys' => array( 'robokassa' ),
					'plugin'       => 'mycred-robokassa/mycred-robokassa.php',
				),
				array(
					'slug'         => 'mycred-coinpayment',
					'text'         => 'CoinPayments',
					'url'          => 'https://mycred.me/store/buycred-coinpayments/',
					'gateway_keys' => array( 'coinpay' ),
					'plugin'       => 'mycred-coinpayment/mycred-coinpayment.php',
				),
				array(
					'slug'         => 'mycred-paymentwall',
					'text'         => 'Paymentwall',
					'url'          => 'https://mycred.me/store/buycred-paymentwall/',
					'gateway_keys' => array( 'paymentwall' ),
					'plugin'       => 'mycred-paymentwall/mycred-paymentwall.php',
				),
				array(
					'slug'         => 'mycred-2co',
					'text'         => '2Checkout',
					'url'          => 'https://mycred.me/store/buycred-2checkout/',
					'gateway_keys' => array( '2checkout' ),
					'plugin'       => 'mycred-2co/mycred-2co.php',
				),
				array(
					'slug'         => 'mycred-coinbase',
					'text'         => 'Coinbase',
					'url'          => 'https://mycred.me/store/buycred-coinbase/',
					'gateway_keys' => array( 'coinbase' ),
					'plugin'       => 'mycred-coinbase/mycred-coinbase.php',
				),
				array(
					'slug'         => 'mycred-wepay',
					'text'         => 'WePay',
					'url'          => 'https://mycred.me/store/buycred-wepay/',
					'gateway_keys' => array( 'wepay' ),
					'plugin'       => 'mycred-wepay/mycred-wepay.php',
				),
				array(
					'slug'         => 'mycred-stripe',
					'text'         => 'Stripe',
					'url'          => 'https://mycred.me/store/buycred-stripe/',
					'gateway_keys' => array( 'stripe', 'stripe_sub' ),
					'plugin'       => 'mycred-stripe/mycred-stripe.php',
				),
				array(
					'slug'         => 'mycred-payfast',
					'text'         => 'PayFast',
					'url'          => 'https://mycred.me/store/buycred-payfast/',
					'gateway_keys' => array( 'payfast' ),
					'plugin'       => 'mycred-payfast/mycred-payfast.php',
				),
			);
		} elseif ( $type === 'cashcred' ) {
			$catalog = array(
				array(
					'slug'         => 'mycred-cashcred-paystack',
					'text'         => 'PayStack',
					'url'          => 'https://mycred.me/store/cashcred-paystack/',
					'gateway_keys' => array( 'paystack' ),
					'plugin'       => 'mycred-cashcred-paystack/mycred-cashcred-paystack.php',
				),
				array(
					'slug'         => 'mycred-cashcred-stripe',
					'text'         => 'Stripe',
					'url'          => 'https://mycred.me/store/cashcred-stripe/',
					'gateway_keys' => array( 'stripe' ),
					'plugin'       => 'mycred-cashcred-stripe/mycred-cashcred-stripe.php',
				),
				array(
					'slug'         => 'mycred-cashcred-paypal',
					'text'         => 'Paypal',
					'url'          => 'https://mycred.me/store/cashcred-paypal/',
					'gateway_keys' => array( 'paypal' ),
					'plugin'       => 'mycred-cashcred-paypal/mycred-cashcred-paypal.php',
				),
			);
		}

		/**
		 * Filter gateway upsell catalog rows.
		 *
		 * @param array  $catalog Catalog rows.
		 * @param string $type    buycred|cashcred
		 */
		return apply_filters( 'mycred_gateway_upsell_catalog', $catalog, $type );
	}
endif;

if ( ! function_exists( 'mycred_gateway_upsell_is_registered' ) ) :
	/**
	 * Whether a gateway upsell catalog entry is already available.
	 *
	 * @param array $entry             Catalog row.
	 * @param array $installed_gateways Registered gateway IDs.
	 * @return bool
	 */
	function mycred_gateway_upsell_is_registered( $entry, $installed_gateways ) {
		if ( ! is_array( $installed_gateways ) ) {
			$installed_gateways = array();
		}

		if ( ! empty( $entry['slug'] ) && mycred_child_addon_is_active( $entry['slug'] ) ) {
			return true;
		}

		if ( ! empty( $entry['gateway_keys'] ) && is_array( $entry['gateway_keys'] ) ) {
			foreach ( $entry['gateway_keys'] as $gateway_key ) {
				if ( array_key_exists( $gateway_key, $installed_gateways ) ) {
					return true;
				}
			}
		}

		if ( ! empty( $entry['plugin'] ) ) {
			if ( ! function_exists( 'is_plugin_active' ) ) {
				require_once ABSPATH . 'wp-admin/includes/plugin.php';
			}

			if ( is_plugin_active( $entry['plugin'] ) ) {
				return true;
			}
		}

		return false;
	}
endif;

if ( ! function_exists( 'mycred_build_gateway_upsell_tabs' ) ) :
	/**
	 * Build Paid gateway upsell accordion rows for buyCred / cashCred settings.
	 *
	 * @param string $type               buycred|cashcred
	 * @param array  $installed_gateways Registered gateways (id => data).
	 * @return array
	 */
	function mycred_build_gateway_upsell_tabs( $type, $installed_gateways = array() ) {
		$tabs    = array();
		$catalog = mycred_get_gateway_upsell_catalog( $type );

		if ( is_array( $installed_gateways ) && ! empty( $installed_gateways ) && array_values( $installed_gateways ) === $installed_gateways ) {
			$keys = $installed_gateways;
			$installed_gateways = array_fill_keys( $keys, true );
		}

		foreach ( $catalog as $entry ) {
			if ( mycred_gateway_upsell_is_registered( $entry, $installed_gateways ) ) {
				continue;
			}

			$tabs[] = array(
				'icon'            => 'dashicons dashicons-admin-generic static',
				'text'            => $entry['text'],
				'additional_text' => 'Paid',
				'url'             => $entry['url'],
				'status'          => 'disabled',
				'plugin'          => isset( $entry['plugin'] ) ? $entry['plugin'] : '',
			);
		}

		if ( ! empty( $tabs ) ) {
			if ( $type === 'buycred' ) {
				$tabs[] = array(
					'icon' => 'dashicons dashicons-admin-generic static',
					'text' => 'More Gateways',
					'url'  => 'https://mycred.me/product-category/buycred-gateways/',
				);
			} elseif ( $type === 'cashcred' ) {
				$tabs[] = array(
					'icon' => 'dashicons dashicons-admin-generic static',
					'text' => 'More Gateways',
					'url'  => 'https://mycred.me/product-category/cashcred-gateways/',
				);
			}
		}

		$filter = ( $type === 'cashcred' ) ? 'mycred_cashcred_more_gateways_tab' : 'mycred_buycred_more_gateways_tab';

		/**
		 * Filter gateway upsell tabs on the settings page.
		 *
		 * @param array $tabs               Upsell tab rows.
		 * @param array $installed_gateways Registered gateways.
		 */
		return apply_filters( $filter, $tabs, $installed_gateways );
	}
endif;

if ( ! function_exists( 'mycred_get_toolkit_free_gateway_upsell_catalog' ) ) :
	/**
	 * Catalog of Toolkit (free) gateway upsell rows for buyCred settings.
	 *
	 * @param string $type buycred|cashcred
	 * @return array
	 */
	function mycred_get_toolkit_free_gateway_upsell_catalog( $type ) {
		$catalog = array();

		if ( $type === 'buycred' ) {
			$catalog = array(
				array(
					'slug'         => 'mycred-square',
					'text'         => 'MyCred Square',
					'url'          => admin_url( 'admin.php?page=mycred-addons' ),
					'gateway_keys' => array( 'mycred-toolkit' ),
					'icon'         => 'dashicons-admin-plugins',
				),
			);
		}

		/**
		 * Filter Toolkit (free) gateway upsell catalog rows.
		 *
		 * @param array  $catalog Catalog rows.
		 * @param string $type    buycred|cashcred
		 */
		return apply_filters( 'mycred_toolkit_free_gateway_upsell_catalog', $catalog, $type );
	}
endif;

if ( ! function_exists( 'mycred_build_toolkit_free_gateway_upsell_tabs' ) ) :
	/**
	 * Build Toolkit (free) gateway upsell accordion rows for buyCred settings.
	 *
	 * Shown when Toolkit is inactive so users can discover free gateways.
	 *
	 * @param string $type               buycred|cashcred
	 * @param array  $installed_gateways Registered gateways (id => data).
	 * @return array
	 */
	function mycred_build_toolkit_free_gateway_upsell_tabs( $type, $installed_gateways = array() ) {
		$tabs = array();

		if ( $type !== 'buycred' ) {
			return $tabs;
		}

		if ( ! defined( 'MYCRED_SHOW_PREMIUM_ADDONS' ) || ! MYCRED_SHOW_PREMIUM_ADDONS ) {
			return $tabs;
		}

		if ( function_exists( 'mycred_is_toolkit_plugin_active' ) && mycred_is_toolkit_plugin_active() ) {
			return $tabs;
		}

		if ( is_array( $installed_gateways ) && ! empty( $installed_gateways ) && array_values( $installed_gateways ) === $installed_gateways ) {
			$keys = $installed_gateways;
			$installed_gateways = array_fill_keys( $keys, true );
		}

		$catalog = mycred_get_toolkit_free_gateway_upsell_catalog( $type );

		foreach ( $catalog as $entry ) {
			if ( mycred_gateway_upsell_is_registered( $entry, $installed_gateways ) ) {
				continue;
			}

			$icon = 'dashicons dashicons-admin-generic static';
			if ( ! empty( $entry['icon'] ) ) {
				$icon = 'dashicons ' . $entry['icon'] . ' static';
			}

			$tabs[] = array(
				'icon'            => $icon,
				'text'            => $entry['text'],
				'additional_text' => 'Free',
				'url'             => $entry['url'],
				'status'          => 'disabled',
			);
		}

		/**
		 * Filter Toolkit (free) gateway upsell tabs on the settings page.
		 *
		 * @param array  $tabs               Upsell tab rows.
		 * @param string $type               buycred|cashcred
		 * @param array  $installed_gateways Registered gateways.
		 */
		return apply_filters( 'mycred_toolkit_free_gateway_upsell_tabs', $tabs, $type, $installed_gateways );
	}
endif;

if ( ! function_exists( 'mycred_get_plus_addon_upsell_catalog' ) ) :
	/**
	 * Plus-addon upsell catalog keyed by parent addon slug.
	 *
	 * @param string $parent_slug Optional parent slug to return a single group.
	 * @return array
	 */
	function mycred_get_plus_addon_upsell_catalog( $parent_slug = '' ) {
		$store_urls = array(
			'mycred-woocommerce-plus' => 'https://mycred.me/store/mycred-woocommerce-plus/',
			'mycred-transfer-plus'    => 'https://mycred.me/store/transfer-plus/',
			'mycred-coupons-plus'     => 'https://mycred.me/store/mycred-coupon-plus/',
			'mycred-email-plus'       => 'https://mycred.me/store/mycred-email-plus/',
			'mycred-birthday-plus'    => 'https://mycred.me/store/mycred-birthday-plus/',
		);

		$catalog = array(
			'woocommerce'   => array(
				array(
					'slug' => 'mycred-woocommerce-plus',
					'text' => 'Coupons',
					'url'  => $store_urls['mycred-woocommerce-plus'],
					'icon' => 'dashicons-tickets-alt',
				),
				array(
					'slug' => 'mycred-woocommerce-plus',
					'text' => 'Restrict Products',
					'url'  => $store_urls['mycred-woocommerce-plus'],
					'icon' => 'dashicons-privacy',
				),
				array(
					'slug' => 'mycred-woocommerce-plus',
					'text' => 'Points History',
					'url'  => $store_urls['mycred-woocommerce-plus'],
					'icon' => 'dashicons-editor-table',
				),
				array(
					'slug' => 'mycred-woocommerce-plus',
					'text' => 'Display Reward',
					'url'  => $store_urls['mycred-woocommerce-plus'],
					'icon' => 'dashicons-welcome-view-site',
				),
				array(
					'slug' => 'mycred-woocommerce-plus',
					'text' => 'Product Referral',
					'url'  => $store_urls['mycred-woocommerce-plus'],
					'icon' => 'dashicons-networking',
				),
				array(
					'slug' => 'mycred-woocommerce-plus',
					'text' => 'Partial Payments',
					'url'  => $store_urls['mycred-woocommerce-plus'],
					'icon' => 'dashicons-money-alt',
				),
				array(
					'slug' => 'mycred-woocommerce-plus',
					'text' => 'My Account',
					'url'  => $store_urls['mycred-woocommerce-plus'],
					'icon' => 'dashicons-performance',
				),
			),
			'transfer'      => array(
				array(
					'slug' => 'mycred-transfer-plus',
					'text' => 'Pending Transfers',
					'url'  => $store_urls['mycred-transfer-plus'],
					'icon' => 'dashicons-admin-plugins',
				),
				array(
					'slug' => 'mycred-transfer-plus',
					'text' => 'Transfer Fees',
					'url'  => $store_urls['mycred-transfer-plus'],
					'icon' => 'dashicons-admin-plugins',
				),
				array(
					'slug' => 'mycred-transfer-plus',
					'text' => 'Transfer via Code',
					'url'  => $store_urls['mycred-transfer-plus'],
					'icon' => 'dashicons-admin-plugins',
				),
			),
			'birthday'      => array(
				array(
					'slug' => 'mycred-birthday-plus',
					'text' => 'Birthday Plus',
					'url'  => $store_urls['mycred-birthday-plus'],
					'icon' => 'dashicons-calendar-alt',
				),
			),
		);

		if ( $parent_slug !== '' && isset( $catalog[ $parent_slug ] ) ) {
			return $catalog[ $parent_slug ];
		}

		return $catalog;
	}
endif;

if ( ! function_exists( 'mycred_build_plus_addon_upsell_tabs' ) ) :
	/**
	 * Build Paid plus-addon upsell accordion rows for a parent settings page.
	 *
	 * @param string $parent_slug Parent addon slug.
	 * @return array
	 */
	function mycred_build_plus_addon_upsell_tabs( $parent_slug ) {
		$tabs    = array();
		$catalog = mycred_get_plus_addon_upsell_catalog( $parent_slug );

		if ( ! is_array( $catalog ) ) {
			return $tabs;
		}

		foreach ( $catalog as $entry ) {
			if ( ! mycred_should_show_child_addon_upsell( $entry['slug'] ) ) {
				continue;
			}

			$icon = 'dashicons dashicons-admin-generic static';
			if ( ! empty( $entry['icon'] ) ) {
				$icon = 'dashicons ' . $entry['icon'] . ' static';
			}

			$tabs[] = array(
				'icon'            => $icon,
				'text'            => $entry['text'],
				'additional_text' => 'Paid',
				'url'             => $entry['url'],
				'status'          => 'disabled',
				'slug'            => $entry['slug'],
			);
		}

		/**
		 * Filter plus-addon upsell tabs on parent settings pages.
		 *
		 * @param array  $tabs        Upsell tab rows.
		 * @param string $parent_slug Parent addon slug.
		 */
		return apply_filters( 'mycred_plus_addon_upsell_tabs', $tabs, $parent_slug );
	}
endif;

if ( ! function_exists( 'mycred_render_plus_addon_upsell_accordions' ) ) :
	/**
	 * Render Paid plus-addon upsell accordions (buyCred gateway markup).
	 *
	 * @param string $parent_slug Parent addon slug.
	 */
	function mycred_render_plus_addon_upsell_accordions( $parent_slug ) {
		if ( ! defined( 'MYCRED_SHOW_PREMIUM_ADDONS' ) || ! MYCRED_SHOW_PREMIUM_ADDONS ) {
			return;
		}

		$tabs = mycred_build_plus_addon_upsell_tabs( $parent_slug );

		foreach ( $tabs as $tab ) {
			$disabled_class = ( isset( $tab['status'] ) && $tab['status'] === 'disabled' ) ? 'disabled' : '';

			?>

<div class="mycred-ui-accordion <?php echo esc_attr( $disabled_class ); ?>">
	<div class="mycred-ui-accordion-header buycred-cashcred-more-tab-btn" data-url="<?php echo esc_attr( $tab['url'] ); ?>">
		<h4 class="mycred-ui-accordion-header-title">
			<span class="dashicons <?php echo esc_attr( $tab['icon'] ); ?> mycred-ui-accordion-header-icon"></span>
			<label><?php echo esc_html( $tab['text'] ); ?></label>
			<?php if ( array_key_exists( 'additional_text', $tab ) && ! empty( $tab['additional_text'] ) ) : ?>
			<span class="mycred-ui-badge"><?php echo esc_html( $tab['additional_text'] ); ?></span>
			<?php endif; ?>
		</h4>
	</div>
	<div class="body" style="display:none; padding: 0px; border: none;"></div>
</div>

			<?php
		}
	}
endif;

if ( ! function_exists( 'mycred_collapse_expanded_addon_slugs' ) ) :
	/**
	 * Remove implicit child slugs from storage when a parent slug expands to them.
	 *
	 * @param array $slugs Stored slugs.
	 * @return array
	 */
	function mycred_collapse_expanded_addon_slugs( $slugs ) {
		if ( ! is_array( $slugs ) ) {
			return array();
		}

		$slugs     = array_values( array_unique( array_filter( $slugs, 'mycred_addons_is_valid_slug' ) ) );
		$collapsed = $slugs;

		foreach ( $slugs as $slug ) {
			$without = array_values( array_diff( $slugs, array( $slug ) ) );

			/**
			 * @param array $without Slugs without the candidate child.
			 */
			$expanded_without = apply_filters( 'mycred_expand_active_addon_slugs', $without );

			if ( in_array( $slug, $expanded_without, true ) ) {
				$collapsed = array_values( array_diff( $collapsed, array( $slug ) ) );
			}
		}

		return array_values( array_unique( array_filter( $collapsed, 'mycred_addons_is_valid_slug' ) ) );
	}
endif;

if ( ! function_exists( 'mycred_get_stored_addon_slugs' ) ) :
	/**
	 * Stored add-on slugs (prefs + legacy), without gateway expansion.
	 *
	 * @return array
	 */
	function mycred_get_stored_addon_slugs() {
		$slugs = array();

		$prefs = get_option( 'mycred_pref_addons', array() );
		if ( ! empty( $prefs['active'] ) && is_array( $prefs['active'] ) ) {
			$slugs = array_merge( $slugs, $prefs['active'] );
		}

		if ( mycred_addons_dual_write_enabled() || ! mycred_addons_is_unified() ) {
			$legacy = get_option( 'mycred_enabled_addons', array() );
			if ( is_array( $legacy ) && ! empty( $legacy ) ) {
				$slugs = array_merge( $slugs, $legacy );
			}
		}

		return array_values( array_unique( array_filter( $slugs, 'mycred_addons_is_valid_slug' ) ) );
	}
endif;

if ( ! function_exists( 'mycred_get_active_addon_slugs' ) ) :
	/**
	 * Single read path for enabled add-on slugs (includes gateway expansion for loaders).
	 *
	 * @return array
	 */
	function mycred_get_active_addon_slugs() {
		$slugs = mycred_get_stored_addon_slugs();

		/**
		 * Expand active add-on slugs (e.g. buy-creds to payment gateway modules).
		 *
		 * @param array $slugs Active slugs.
		 */
		$slugs = apply_filters( 'mycred_expand_active_addon_slugs', $slugs );

		return array_values( array_unique( array_filter( $slugs, 'mycred_addons_is_valid_slug' ) ) );
	}
endif;

if ( ! function_exists( 'mycred_merge_legacy_into_addon_prefs' ) ) :
	/**
	 * Merge legacy/archive slugs into mycred_pref_addons.active.
	 *
	 * @param array $extra_sources Additional option arrays to merge.
	 * @return bool Whether prefs were updated.
	 */
	function mycred_merge_legacy_into_addon_prefs( $extra_sources = array() ) {
		$sources = array();

		// Live legacy option is only merged during dual-write (pre-finalize migration).
		if ( mycred_addons_dual_write_enabled() ) {
			$legacy = get_option( 'mycred_enabled_addons', array() );
			if ( is_array( $legacy ) && ! empty( $legacy ) ) {
				$sources[] = $legacy;
			}
		}

		if ( is_array( $extra_sources ) && ! empty( $extra_sources ) ) {
			$sources[] = $extra_sources;
		}

		if ( empty( $sources ) ) {
			return false;
		}

		$prefs = get_option( 'mycred_pref_addons', array( 'active' => array() ) );
		if ( ! isset( $prefs['active'] ) || ! is_array( $prefs['active'] ) ) {
			$prefs['active'] = array();
		}

		$incoming = array();
		foreach ( $sources as $source ) {
			if ( is_array( $source ) ) {
				$incoming = array_merge( $incoming, $source );
			}
		}

		$incoming = array_values( array_unique( array_filter( $incoming, 'mycred_addons_is_valid_slug' ) ) );
		$merged   = mycred_collapse_expanded_addon_slugs(
			array_values( array_unique( array_merge( $prefs['active'], $incoming ) ) )
		);

		if ( $merged === $prefs['active'] ) {
			return false;
		}

		$prefs['active'] = $merged;

		if ( function_exists( 'mycred_update_option' ) ) {
			mycred_update_option( 'mycred_pref_addons', $prefs );
		} else {
			update_option( 'mycred_pref_addons', $prefs );
		}

		if ( mycred_addons_dual_write_enabled() ) {
			mycred_sync_legacy_enabled_addons( $merged );
		}

		return true;
	}
endif;

if ( ! function_exists( 'mycred_set_addon_active' ) ) :
	/**
	 * Single write path for enabling or disabling an add-on slug.
	 *
	 * @param string   $slug   Add-on slug.
	 * @param bool|null $active True to enable, false to disable, null to toggle.
	 * @return array{success:bool,toggle:bool}
	 */
	function mycred_set_addon_active( $slug, $active = null ) {
		$slug = sanitize_text_field( $slug );

		if ( $slug === '' ) {
			return array(
				'success' => false,
				'toggle'  => false,
			);
		}

		$prefs = get_option( 'mycred_pref_addons', array( 'active' => array() ) );
		if ( ! isset( $prefs['active'] ) || ! is_array( $prefs['active'] ) ) {
			$prefs['active'] = array();
		}

		$is_active = in_array( $slug, $prefs['active'], true );

		if ( null === $active ) {
			$active = ! $is_active;
		}

		if ( $active ) {
			if ( ! $is_active ) {
				$prefs['active'][] = $slug;
			}
			$toggle = true;
		} else {
			$prefs['active'] = array_values( array_diff( $prefs['active'], array( $slug ) ) );
			$toggle = false;
		}

		$prefs['active'] = mycred_collapse_expanded_addon_slugs( $prefs['active'] );

		if ( function_exists( 'mycred_update_option' ) ) {
			mycred_update_option( 'mycred_pref_addons', $prefs );
		} else {
			update_option( 'mycred_pref_addons', $prefs );
		}

		if ( mycred_addons_dual_write_enabled() ) {
			mycred_sync_legacy_enabled_addons( $prefs['active'] );
		}

		return array(
			'success' => true,
			'toggle'  => (bool) $toggle,
		);
	}
endif;

if ( ! function_exists( 'mycred_normalize_stored_addon_prefs' ) ) :
	/**
	 * Collapse implicit child slugs in prefs when toolkit expansion is available.
	 */
	function mycred_normalize_stored_addon_prefs() {
		if ( ! mycred_addons_is_unified() ) {
			return false;
		}

		$prefs = get_option( 'mycred_pref_addons', array( 'active' => array() ) );
		if ( ! isset( $prefs['active'] ) || ! is_array( $prefs['active'] ) ) {
			$prefs['active'] = array();
		}

		$collapsed = mycred_collapse_expanded_addon_slugs( $prefs['active'] );

		if ( $collapsed === $prefs['active'] ) {
			return false;
		}

		$prefs['active'] = $collapsed;

		if ( function_exists( 'mycred_update_option' ) ) {
			mycred_update_option( 'mycred_pref_addons', $prefs );
		} else {
			update_option( 'mycred_pref_addons', $prefs );
		}

		if ( mycred_addons_dual_write_enabled() ) {
			mycred_sync_legacy_enabled_addons( $prefs['active'] );
		}

		return true;
	}
endif;

if ( ! function_exists( 'mycred_maybe_migrate_addons_schema' ) ) :
	/**
	 * One-time migration to unified add-ons schema.
	 */
	function mycred_maybe_migrate_addons_schema() {
		if ( ! defined( 'MYCRED_ADDONS_UNIFIED_UI' ) || ! MYCRED_ADDONS_UNIFIED_UI ) {
			return;
		}

		if ( ! function_exists( 'mycred_is_installed' ) || ! mycred_is_installed() ) {
			return;
		}

		$schema = mycred_addons_schema();

		if ( isset( $schema['version'] ) && (int) $schema['version'] >= 2 ) {
			mycred_maybe_finalize_addons_schema();
			return;
		}

		$prefs = get_option( 'mycred_pref_addons', array( 'active' => array() ) );
		if ( ! isset( $prefs['active'] ) || ! is_array( $prefs['active'] ) ) {
			$prefs['active'] = array();
		}

		$legacy = get_option( 'mycred_enabled_addons', array() );
		if ( is_array( $legacy ) && ! empty( $legacy ) ) {
			$legacy_flat     = array_filter( $legacy, 'mycred_addons_is_valid_slug' );
			$prefs['active'] = mycred_collapse_expanded_addon_slugs(
				array_values( array_unique( array_merge( $prefs['active'], $legacy_flat ) ) )
			);
		}

		if ( function_exists( 'mycred_update_option' ) ) {
			mycred_update_option( 'mycred_pref_addons', $prefs );
		} else {
			update_option( 'mycred_pref_addons', $prefs );
		}

		mycred_sync_legacy_enabled_addons( $prefs['active'] );

		update_option(
			MYCRED_ADDONS_SCHEMA_OPTION,
			array(
				'version'    => 2,
				'dual_write' => true,
				'migrated'   => time(),
			)
		);

		mycred_maybe_finalize_addons_schema();
	}
	endif;

if ( ! function_exists( 'mycred_maybe_seed_default_builtin_addons' ) ) :
	/**
	 * Ensure fresh installs (or broken migrations) activate all built-in add-ons.
	 *
	 * Mirrors myCRED_Setup::load() default: active = array_keys( installed ).
	 */
	function mycred_maybe_seed_default_builtin_addons() {
		if ( ! defined( 'MYCRED_ADDONS_UNIFIED_UI' ) || ! MYCRED_ADDONS_UNIFIED_UI ) {
			return;
		}

		if ( ! function_exists( 'mycred_is_installed' ) || ! mycred_is_installed() ) {
			return;
		}

		$schema = mycred_addons_schema();
		if ( ! empty( $schema['builtin_defaults_seeded'] ) ) {
			return;
		}

		$prefs = get_option( 'mycred_pref_addons', false );
		if ( false === $prefs || ! is_array( $prefs ) ) {
			return;
		}

		if ( isset( $prefs['active'] ) && is_array( $prefs['active'] ) ) {
			return;
		}

		if ( ! defined( 'myCRED_MODULES_DIR' ) ) {
			return;
		}

		require_once myCRED_MODULES_DIR . 'mycred-module-addons.php';

		if ( ! class_exists( 'myCRED_Addons_Module' ) ) {
			return;
		}

		$addons_module    = new myCRED_Addons_Module();
		$installed_addons = $addons_module->get();

		if ( empty( $installed_addons ) || ! is_array( $installed_addons ) ) {
			return;
		}

		$prefs['installed'] = $installed_addons;
		$prefs['active']    = array_keys( $installed_addons );

		if ( function_exists( 'mycred_update_option' ) ) {
			mycred_update_option( 'mycred_pref_addons', $prefs );
		} else {
			update_option( 'mycred_pref_addons', $prefs );
		}

		$schema['builtin_defaults_seeded'] = true;
		update_option( MYCRED_ADDONS_SCHEMA_OPTION, $schema );
	}
endif;

if ( ! function_exists( 'mycred_maybe_finalize_addons_schema' ) ) :
	/**
	 * End dual-write when toolkit declares unified support.
	 */
	function mycred_maybe_finalize_addons_schema() {
		if ( ! mycred_addons_is_unified() || ! mycred_toolkit_supports_unified() ) {
			return;
		}

		$schema = mycred_addons_schema();

		if ( empty( $schema['dual_write'] ) ) {
			return;
		}

		$legacy = get_option( 'mycred_enabled_addons', array() );
		if ( is_array( $legacy ) && ! empty( $legacy ) ) {
			update_option( 'mycred_enabled_addons_archive', $legacy, false );
			mycred_merge_legacy_into_addon_prefs( $legacy );
		}

		$schema['dual_write'] = false;
		$schema['finalized']  = time();

		update_option( MYCRED_ADDONS_SCHEMA_OPTION, $schema );

		delete_option( 'mycred_enabled_addons' );
	}
endif;

if ( ! function_exists( 'mycred_addons_unified_admin_notice' ) ) :
	/**
	 * Notice when core is unified but toolkit has not been updated yet.
	 */
	function mycred_addons_unified_admin_notice() {
		if ( ! is_admin() || ! current_user_can( 'manage_options' ) ) {
			return;
		}

		if ( ! mycred_addons_is_unified() || mycred_toolkit_supports_unified() ) {
			return;
		}

		if ( ! mycred_is_toolkit_plugin_active() ) {
			return;
		}

		echo '<div class="notice notice-info is-dismissible"><p>';
		echo esc_html__( 'myCred Add-ons have been unified. Please update myCred Toolkit to the latest version for the best experience. Your enabled add-ons will continue to work.', 'mycred' );
		echo '</p></div>';
	}
endif;

if ( did_action( 'plugins_loaded' ) ) {
	mycred_maybe_migrate_addons_schema();
	mycred_maybe_seed_default_builtin_addons();
} else {
	add_action( 'plugins_loaded', 'mycred_maybe_migrate_addons_schema', 5 );
	add_action( 'plugins_loaded', 'mycred_maybe_seed_default_builtin_addons', 6 );
}

add_action( 'admin_notices', 'mycred_addons_unified_admin_notice' );
