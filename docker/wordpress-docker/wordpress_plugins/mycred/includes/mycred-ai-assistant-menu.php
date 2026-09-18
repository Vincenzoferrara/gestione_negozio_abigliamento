<?php
/**
 * myCred AI Assistant admin menu (always visible under myCred).
 *
 * Open chat only when Toolkit is active and the ai-assistant add-on is enabled.
 * All other cases open the blog guide in a new tab.
 *
 * @package myCred
 * @since 2.9.6
 */

if ( ! defined( 'myCRED_VERSION' ) ) {
	exit;
}

if ( ! defined( 'MYCRED_AI_ASSISTANT_PAGE' ) ) {
	define( 'MYCRED_AI_ASSISTANT_PAGE', 'mycred-ai-assistant' );
}

if ( ! defined( 'MYCRED_AI_ASSISTANT_ADDON_SLUG' ) ) {
	define( 'MYCRED_AI_ASSISTANT_ADDON_SLUG', 'ai-assistant' );
}

if ( ! defined( 'MYCRED_AI_ASSISTANT_BLOG_URL' ) ) {
	define( 'MYCRED_AI_ASSISTANT_BLOG_URL', 'https://codex.mycred.me/docs/toolkit/mycred-ai-assistant' );
}

if ( ! function_exists( 'mycred_ai_assistant_is_addon_enabled' ) ) :
	/**
	 * Whether the ai-assistant toolkit add-on is enabled.
	 *
	 * @return bool
	 */
	function mycred_ai_assistant_is_addon_enabled() {
		if ( function_exists( 'mycred_get_active_addon_slugs' ) ) {
			return in_array( MYCRED_AI_ASSISTANT_ADDON_SLUG, mycred_get_active_addon_slugs(), true );
		}

		$enabled = get_option( 'mycred_enabled_addons', array() );

		return is_array( $enabled ) && in_array( MYCRED_AI_ASSISTANT_ADDON_SLUG, $enabled, true );
	}
endif;

if ( ! function_exists( 'mycred_ai_assistant_is_toolkit_active' ) ) :
	/**
	 * Whether myCred Toolkit is active.
	 *
	 * @return bool
	 */
	function mycred_ai_assistant_is_toolkit_active() {
		if ( function_exists( 'mycred_is_toolkit_plugin_active' ) ) {
			return mycred_is_toolkit_plugin_active();
		}

		if ( ! function_exists( 'is_plugin_active' ) ) {
			require_once ABSPATH . 'wp-admin/includes/plugin.php';
		}

		return is_plugin_active( 'mycred-toolkit/mycred-toolkit.php' );
	}
endif;

if ( ! function_exists( 'mycred_ai_assistant_can_open' ) ) :
	/**
	 * Whether the AI Assistant chat may load (Toolkit active + add-on enabled).
	 *
	 * @return bool
	 */
	function mycred_ai_assistant_can_open() {
		if ( ! mycred_ai_assistant_is_toolkit_active() ) {
			return false;
		}

		return mycred_ai_assistant_is_addon_enabled();
	}
endif;

if ( ! function_exists( 'mycred_ai_assistant_menu_badge_html' ) ) :
	/**
	 * Sidebar menu "New" pill HTML.
	 *
	 * @return string
	 */
	function mycred_ai_assistant_menu_badge_html() {
		return ' <span class="mycred-ai-menu-new" style="display:inline-block;margin-left:6px;padding:2px 8px;border-radius:10px;background:#3b82f6;color:#fff;font-size:10px;font-weight:600;line-height:1.4;vertical-align:middle;">'
			. esc_html__( 'New', 'mycred' )
			. '</span>';
	}
endif;

if ( ! class_exists( 'myCRED_AI_Assistant_Menu' ) ) :

	class myCRED_AI_Assistant_Menu {

		/**
		 * @var myCRED_AI_Assistant_Menu|null
		 */
		protected static $_instance = null;

		/**
		 * @return myCRED_AI_Assistant_Menu
		 */
		public static function instance() {
			if ( is_null( self::$_instance ) ) {
				self::$_instance = new self();
			}
			return self::$_instance;
		}

		public function __construct() {
			add_action( 'mycred_add_menu', array( $this, 'register_menu' ), 0 );
			add_action( 'admin_footer', array( $this, 'blog_menu_new_tab_script' ) );
		}

		/**
		 * Register AI Assistant under the myCred main menu.
		 */
		public function register_menu() {

			if ( mycred_override_settings() && ! mycred_is_main_site() ) {
				return;
			}

			$mycred = mycred();
			if ( ! is_object( $mycred ) ) {
				return;
			}

			$page_title = __( 'AI Assistant', 'mycred' );
			$menu_label = $page_title . mycred_ai_assistant_menu_badge_html();

			mycred_add_main_submenu(
				$page_title,
				$menu_label,
				$mycred->get_point_admin_capability(),
				MYCRED_AI_ASSISTANT_PAGE,
				array( $this, 'render_admin_page' ),
				0
			);
		}

		/**
		 * Sidebar menu: open blog in a new tab when chat cannot load.
		 */
		public function blog_menu_new_tab_script() {

			if ( mycred_ai_assistant_can_open() ) {
				return;
			}

			$blog_url = esc_url( MYCRED_AI_ASSISTANT_BLOG_URL );
			$page     = MYCRED_AI_ASSISTANT_PAGE;
			?>
			<script>
			(function () {
				var blogUrl = <?php echo wp_json_encode( $blog_url ); ?>;
				document.querySelectorAll('#adminmenu a[href$="page=<?php echo esc_js( $page ); ?>"]').forEach(function (link) {
					link.setAttribute('href', blogUrl);
					link.setAttribute('target', '_blank');
					link.setAttribute('rel', 'noopener noreferrer');
				});
			})();
			</script>
			<?php
		}

		/**
		 * Render chat via Toolkit, show an admin notice, or open blog in a new tab.
		 */
		public function render_admin_page() {

			if ( mycred_ai_assistant_can_open() && class_exists( 'myCRED_AI_Admin' ) ) {
				myCRED_AI_Admin::instance()->admin_page();
				return;
			}

			if ( mycred_ai_assistant_can_open() ) {
				$this->render_unavailable_notice();
				return;
			}

			$this->open_blog_new_tab();
		}

		/**
		 * Admin notice when the add-on is enabled but chat cannot load.
		 */
		private function render_unavailable_notice() {
			?>
			<div class="wrap">
				<h1><?php esc_html_e( 'AI Assistant', 'mycred' ); ?></h1>
				<div class="notice notice-warning">
					<p>
						<?php
						esc_html_e(
							'The AI Assistant add-on is enabled, but WordPress AI support is not available in this environment. Ensure you are running WordPress 7.0 or later and that AI features are not disabled (for example via WP_AI_SUPPORT).',
							'mycred'
						);
						?>
					</p>
				</div>
			</div>
			<?php
		}

		/**
		 * Open blog in new tab and return user to myCred dashboard.
		 */
		private function open_blog_new_tab() {

			$blog_url  = esc_url_raw( MYCRED_AI_ASSISTANT_BLOG_URL );
			$admin_url = esc_url_raw( admin_url( 'admin.php?page=' . MYCRED_MAIN_SLUG ) );
			?>
			<script>
			window.open(<?php echo wp_json_encode( $blog_url ); ?>, '_blank', 'noopener,noreferrer');
			window.location.replace(<?php echo wp_json_encode( $admin_url ); ?>);
			</script>
			<?php
		}
	}

	myCRED_AI_Assistant_Menu::instance();

endif;
