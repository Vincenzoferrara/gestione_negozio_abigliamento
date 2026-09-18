<?php
if ( ! class_exists( 'myCRED_Loyalty_Widget_Frontend' ) ) :

    class myCRED_Loyalty_Widget_Frontend {

        private static $_instance = null;

        public static function instance() {
            if ( is_null( self::$_instance ) ) {
                self::$_instance = new self();
            }
            return self::$_instance;
        }

        public function __construct() {
            add_action( 'wp_enqueue_scripts', array( $this, 'enqueue_scripts' ) );
            add_action( 'wp_footer', array( $this, 'render_widget_root' ) );
        }

        private function should_display_widget() {
            $settings = get_option( 'mycred_loyalty_widget_settings', array() );
            if ( ! class_exists( 'myCRED_Loyalty_Widget_API' ) ) {
                return false;
            }

            return myCRED_Loyalty_Widget_API::visitor_can_see_widget( $settings );
        }

        public function enqueue_scripts() {
            if ( ! $this->should_display_widget() ) {
                return;
            }
            
            $settings = get_option( 'mycred_loyalty_widget_settings', array() );
            $general  = isset( $settings['general'] ) ? $settings['general'] : array();


            // 3. Enqueue Fonts & Frontend Bundle
            wp_enqueue_style( 'mycred-loyalty-widget-fonts', 'https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;600;700&display=swap', array(), '1.0.0' );

            $build_file = plugin_dir_path( __FILE__ ) . 'build/frontend.bundle.js';
            $build_url  = plugin_dir_url( __FILE__ ) . 'build/frontend.bundle.js';

            if ( file_exists( $build_file ) ) {
                $asset_file = include( plugin_dir_path( __FILE__ ) . 'build/frontend.bundle.asset.php' );
                
                wp_enqueue_script(
                    'mycred-loyalty-widget-frontend',
                    $build_url,
                    $asset_file['dependencies'],
                    $asset_file['version'],
                    true
                );

                // 4. Localize Data
                $user_id = get_current_user_id();
                $user_data = array(
                    'is_logged_in' => (bool) $user_id,
                );

                if ( $user_id ) {
                    $mycred      = mycred();
                    $wp_user     = get_userdata( $user_id );

                    $user_data['display_name']      = $wp_user ? $wp_user->display_name : '';
                    $user_data['balance']           = $mycred->get_users_balance( $user_id );
                    $user_data['formatted_balance'] = $mycred->format_creds( $user_data['balance'] );
                    $user_data['avatar']            = get_avatar_url( $user_id );
                    $user_data['point_label']       = $mycred->plural();

                    // All point type balances
                    $all_balances = array();
                    if ( function_exists( 'mycred_get_types' ) ) {
                        foreach ( mycred_get_types() as $type_key => $type_label ) {
                            $mc = mycred( $type_key );
                            
                            // Retrieve point type image URL
                            $attachment_id = '';
                            if ( is_array( $mc->core ) && isset( $mc->core['attachment_id'] ) ) {
                                $attachment_id = $mc->core['attachment_id'];
                            } elseif ( is_object( $mc->core ) && property_exists( $mc->core, 'attachment_id' ) ) {
                                $attachment_id = $mc->core->attachment_id;
                            }

                            if ( empty( $attachment_id ) && function_exists( 'mycred_get_default_point_image_id' ) ) {
                                $attachment_id = mycred_get_default_point_image_id();
                            }

                            $image_url = '';
                            if ( ! empty( $attachment_id ) ) {
                                $image_url = wp_get_attachment_url( $attachment_id );
                            }

                            $all_balances[] = array(
                                'type'      => $type_key,
                                'label'     => $mc->plural(),
                                'balance'   => $mc->get_users_balance( $user_id ),
                                'formatted' => $mc->format_creds( $mc->get_users_balance( $user_id ) ),
                                'image_url' => $image_url,
                            );
                        }
                    }
                    $user_data['all_balances'] = $all_balances;

                    // Get rank if available
                    if ( function_exists( 'mycred_get_users_rank' ) ) {
                        $rank = mycred_get_users_rank( $user_id );
                        if ( is_object( $rank ) && isset( $rank->post_title ) ) {
                            $user_data['rank'] = $rank->post_title;

                            // Rank image/logo
                            $rank_logo_id = get_post_meta( $rank->ID, 'mycred_rank_logo', true );
                            if ( $rank_logo_id ) {
                                $user_data['rank_image'] = wp_get_attachment_url( $rank_logo_id );
                            }

                            // Rank min/max for progress display
                            $rank_min = get_post_meta( $rank->ID, 'mycred_rank_min', true );
                            $rank_max = get_post_meta( $rank->ID, 'mycred_rank_max', true );
                            $user_data['rank_min'] = $rank_min !== '' ? (float) $rank_min : 0;
                            $user_data['rank_max'] = $rank_max !== '' ? (float) $rank_max : 0;
                        }
                    }

                    // Earned badges for this user
                    $user_badges = array();
                    // Check if WooCoupon badge reward is configured (mycred-toolkit-pro)
                    $woo_badge_coupons_enabled = false;
                    $mycred_pref_woo = get_option( 'mycred_pref_woo', array() );
                    if ( ! empty( $mycred_pref_woo['mwp_coupons']['badge'] ) ) {
                        $woo_badge_coupons_enabled = true;
                    }

                    // Get the user's already-generated badge coupons
                    $users_badge_coupons = get_user_meta( $user_id, 'mycred_badges_coupons', true );
                    if ( empty( $users_badge_coupons ) ) {
                        $users_badge_coupons = array();
                    }

                    if ( function_exists( 'mycred_get_badge_ids' ) && function_exists( 'mycred_get_badge' ) ) {
                        $badge_ids = mycred_get_badge_ids();
                        foreach ( $badge_ids as $badge_id ) {
                            $badge = mycred_get_badge( $badge_id );
                            if ( $badge === false ) continue;
                            $level_index = $badge->get_users_current_level( $user_id );
                            if ( $level_index !== false ) {
                                $badge_entry = array(
                                    'id'        => $badge_id,
                                    'title'     => $badge->title,
                                    'image_url' => ! empty( $badge->main_image_url ) ? $badge->main_image_url : '',
                                    'level'     => $level_index + 1,
                                    'coupon'    => null,
                                );

                                // Attach WooCommerce coupon reward if enabled
                                if ( $woo_badge_coupons_enabled ) {
                                    $woo_discount = get_post_meta( $badge_id, 'woo_discount', true );
                                    if ( ! empty( $woo_discount[ $level_index ] ) ) {
                                        $lvl_reward = $woo_discount[ $level_index ];

                                        // Check if a coupon has already been generated for this badge+level
                                        $generated_code = '';
                                        foreach ( $users_badge_coupons as $entry ) {
                                            if (
                                                isset( $entry['badge_id'], $entry['level'], $entry['coupon_id'] ) &&
                                                $entry['badge_id'] == $badge_id &&
                                                $entry['level'] == $level_index
                                            ) {
                                                $generated_code = get_post_field( 'post_title', $entry['coupon_id'] );
                                                break;
                                            }
                                        }

                                        $badge_entry['coupon'] = array(
                                            'discount_type'  => ! empty( $lvl_reward['discount_type'] ) ? $lvl_reward['discount_type'] : 'fixed',
                                            'amount'         => ! empty( $lvl_reward['discount_amount'] ) ? $lvl_reward['discount_amount'] : '0',
                                            'code'           => ! empty( $lvl_reward['mycred_coupon_code_badge'] ) ? $lvl_reward['mycred_coupon_code_badge'] : '',
                                            'generated_code' => $generated_code,
                                        );
                                    }
                                }

                                $user_badges[] = $badge_entry;
                            }
                        }
                    }
                    $user_data['badges'] = $user_badges;
                }

                // Get active myCred hooks
                $active_hooks = array();
                if ( function_exists( 'mycred_get_types' ) ) {
                    $types = mycred_get_types();
                    foreach ( $types as $type => $label ) {
                        $hook_prefs = get_option( 'mycred_pref_hooks' . ( $type !== 'mycred_default' ? '_' . $type : '' ) );
                        if ( ! empty( $hook_prefs['active'] ) ) {
                            $hooks_module = new myCRED_Hooks_Module( $type );
                            $installed = $hooks_module->get();
                            $mycred_obj = mycred( $type );
                            
                            
                            foreach ( $hook_prefs['active'] as $hook_id ) {
                                if ( isset( $installed[ $hook_id ] ) ) {
                                    $raw_title = $installed[ $hook_id ]['title'];
                                    
                                    // Get hook amount
                                    $amount = 0;
                                    if ( isset( $hook_prefs['hook_prefs'][ $hook_id ] ) ) {
                                        $amount = $this->get_hook_amount( $hook_prefs['hook_prefs'][ $hook_id ] );
                                    }

                                    $active_hooks[] = array(
                                        'id'               => $hook_id,
                                        'point_type'       => $type,
                                        'category'         => $this->get_hook_category( $hook_id ),
                                        'title'            => $mycred_obj->template_tags_general( $raw_title ),
                                        'raw_title'        => $raw_title,
                                        'amount'           => $amount,
                                        'formatted_amount' => $mycred_obj->format_creds( $amount ),
                                        'singular'         => $mycred_obj->singular(),
                                        'plural'           => $mycred_obj->plural(),
                                    );
                                }
                            }
                        }
                    }
                }

                // Get all point types
                $point_types = array();
                if ( function_exists( 'mycred_get_types' ) ) {
                    $all_types = mycred_get_types();

                    // myCred stores custom point types in 'mycred_types' option
                    $db_types = get_option( 'mycred_types', array() );
                    if ( ! empty( $db_types ) && is_array( $db_types ) ) {
                        foreach ( $db_types as $type_key => $type_label ) {
                            if ( ! isset( $all_types[ $type_key ] ) ) {
                                $all_types[ $type_key ] = $type_label;
                            }
                        }
                    }

                    foreach ( $all_types as $type => $label ) {
                        if ( function_exists( 'mycred_get_point_type_name' ) ) {
                            $point_types[ $type ] = mycred_get_point_type_name( $type, false );
                        } else {
                            $mycred_obj = mycred( $type );
                            $point_types[ $type ] = $mycred_obj->plural();
                        }
                    }
                }
                
                // Ensure default is always there
                if ( ! isset( $point_types['mycred_default'] ) ) {
                    $mycred_obj = mycred();
                    $point_types['mycred_default'] = $mycred_obj->plural();
                }

                // WooCommerce Gateway settings
                $woo_gateway = array( 'enabled' => false );
                if ( class_exists( 'WooCommerce' ) ) {
                    $gw_settings   = get_option( 'woocommerce_mycred_settings', array() );
                    $gw_enabled    = isset( $gw_settings['enabled'] ) && $gw_settings['enabled'] === 'yes';
                    if ( $gw_enabled ) {
                        $gw_point_type = isset( $gw_settings['point_type'] ) ? $gw_settings['point_type'] : 'mycred_default';
                        if ( ! mycred_point_type_exists( $gw_point_type ) ) {
                            $gw_point_type = 'mycred_default';
                        }
                        $gw_mycred     = mycred( $gw_point_type );
                        $gw_rate       = isset( $gw_settings['exchange_rate'] ) && is_numeric( $gw_settings['exchange_rate'] ) ? (float) $gw_settings['exchange_rate'] : 1;
                        $gw_balance    = $gw_mycred->get_users_balance( $user_id, $gw_point_type );
                        $currency      = html_entity_decode( get_woocommerce_currency_symbol(), ENT_QUOTES | ENT_HTML5, 'UTF-8' );
                        $woo_gateway   = array(
                            'enabled'         => true,
                            'point_type'      => $gw_point_type,
                            'point_label'     => $gw_mycred->plural(),
                            'exchange_rate'   => $gw_rate,
                            'currency_symbol' => $currency,
                            'user_balance'    => $gw_balance,
                            'formatted_balance' => $gw_mycred->format_creds( $gw_balance ),
                        );
                    }
                }

                // Partial Payment settings (myCRED Toolkit Pro)
                $woo_partial = array( 'enabled' => false );
                if ( class_exists( 'WooCommerce' ) ) {
                    $woo_pref   = get_option( 'mycred_pref_woo', array() );
                    $pp_prefs   = isset( $woo_pref['mwp_partial_payments'] ) ? $woo_pref['mwp_partial_payments'] : array();
                    if ( ! empty( $pp_prefs['enable'] ) ) {
                        // Collect per-type exchange rates
                        $pp_types = array();
                        if ( function_exists( 'mycred_get_types' ) ) {
                            foreach ( mycred_get_types() as $pt => $lbl ) {
                                $pt_mycred    = mycred( $pt );
                                $pp_settings  = isset( $pt_mycred->core['partial_payment_settings'] ) ? $pt_mycred->core['partial_payment_settings'] : array();
                                $pp_rate      = isset( $pp_settings['exchange_rate'] ) && is_numeric( $pp_settings['exchange_rate'] ) && (float) $pp_settings['exchange_rate'] > 0
                                    ? (float) $pp_settings['exchange_rate'] : 1;
                                $pp_balance   = $pt_mycred->get_users_balance( $user_id, $pt );
                                $pp_types[]   = array(
                                    'key'               => $pt,
                                    'label'             => $pt_mycred->plural(),
                                    'exchange_rate'     => $pp_rate,
                                    'user_balance'      => $pp_balance,
                                    'formatted_balance' => $pt_mycred->format_creds( $pp_balance ),
                                );
                            }
                        }
                        $currency        = html_entity_decode( get_woocommerce_currency_symbol(), ENT_QUOTES | ENT_HTML5, 'UTF-8' );
                        $woo_partial = array(
                            'enabled'         => true,
                            'currency_symbol' => $currency,
                            'max_percent'     => isset( $pp_prefs['max'] ) ? (int) $pp_prefs['max'] : 100,
                            'point_types'     => $pp_types,
                        );
                    }
                }

                $is_toolkit_pro_active = false;
                $active_plugins = (array) get_option( 'active_plugins', array() );
                if ( in_array( 'mycred-toolkit-pro/mycred-toolkit-pro.php', $active_plugins, true ) ) {
                    if( file_exists( WP_PLUGIN_DIR . '/mycred-toolkit-pro/includes/mycred-toolkit-plan-check.php' ) ) {
                        $is_toolkit_pro_active = true;    
                    }
                }

                if ( class_exists( 'myCRED_Loyalty_Widget_API' ) ) {
                    $defaults = myCRED_Loyalty_Widget_API::instance()->get_default_settings();
                    $settings = myCRED_Loyalty_Widget_API::merge_defaults( $settings, $defaults );
                }

                wp_localize_script( 'mycred-loyalty-widget-frontend', 'mycredLoyaltyWidget', array(
                    'settings'            => $settings,
                    'user'                => $user_data,
                    'active_hooks'        => $active_hooks,
                    'point_types'         => $point_types,
                    'rest_url'            => esc_url_raw( rest_url( 'mycred-loyalty-widget/v1' ) ),
                    'nonce'               => wp_create_nonce( 'wp_rest' ),
                    'assets_url'          => plugin_dir_url( __FILE__ ) . 'src/assets/widget-icon/',
                    'is_admin'            => current_user_can( 'manage_options' ),
                    'settings_url'        => admin_url( 'admin.php?page=mycred-loyalty-widget' ),
                    'addons'              => array(
                        'ranks_enabled'  => function_exists( 'mycred_get_users_rank' ),
                        'badges_enabled' => function_exists( 'mycred_get_badge_ids' ),
                        'is_toolkit_pro_active' => $is_toolkit_pro_active,
                    ),
                    'woo_gateway'         => $woo_gateway,
                    'woo_partial_payment' => $woo_partial,
                ) );
            }
        }

        private function get_hook_amount( $prefs ) {
            if ( ! is_array( $prefs ) ) {
                return is_numeric( $prefs ) ? $prefs : 0;
            }
            
            if ( isset( $prefs['creds'] ) && ! is_array( $prefs['creds'] ) ) {
                return $prefs['creds'];
            }
            if ( isset( $prefs['amount'] ) && ! is_array( $prefs['amount'] ) ) {
                return $prefs['amount'];
            }
            
            foreach ( $prefs as $key => $value ) {
                if ( is_array( $value ) ) {
                    if ( isset( $value['creds'] ) && ! is_array( $value['creds'] ) ) {
                        return $value['creds'];
                    }
                    if ( isset( $value['amount'] ) && ! is_array( $value['amount'] ) ) {
                        return $value['amount'];
                    }
                }
            }
            
            if ( isset( $prefs['creds'] ) && is_array( $prefs['creds'] ) ) {
                foreach ( $prefs['creds'] as $val ) {
                    if ( is_numeric( $val ) && $val > 0 ) return $val;
                }
            }

            return 0;
        }

        private function get_hook_category( $hook_id ) {
            $hook_id = strtolower( $hook_id );
            if ( strpos( $hook_id, 'woocommerce' ) !== false ) return 'woocommerce';
            if ( strpos( $hook_id, 'buddypress' ) !== false || strpos( $hook_id, 'bp_' ) === 0 ) return 'buddypress';
            if ( strpos( $hook_id, 'bbpress' ) !== false || strpos( $hook_id, 'forum' ) !== false ) return 'forum';
            return 'wordpress';
        }

        public function render_widget_root() {
            if ( ! $this->should_display_widget() ) {
                return;
            }
            echo '<div id="mycred-loyalty-widget-root"></div>';
        }

    }

    myCRED_Loyalty_Widget_Frontend::instance();

endif;
