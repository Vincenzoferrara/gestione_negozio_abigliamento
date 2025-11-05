<?php
/**
 * Dashboard page.
 *
 * @package Kliken: Ads + Pixel for Meta
 */

defined( 'ABSPATH' ) || exit;

?>

<div class="wrap kk-wrapper">
	<div class="connected">
		<div class="connected-header flex align-center">
			<svg width="41" height="41" viewBox="0 0 41 41" fill="none" xmlns="http://www.w3.org/2000/svg">
				<g clip-path="url(#clip0_1000_17144)">
					<path fill-rule="evenodd" clip-rule="evenodd" d="M40.7139 20.293C40.7139 9.24727 31.7596 0.292969 20.7139 0.292969C9.66816 0.292969 0.713867 9.24727 0.713867 20.293C0.713867 30.2755 8.02758 38.5496 17.5889 40.05V26.0742H12.5107V20.293H17.5889V15.8867C17.5889 10.8742 20.5747 8.10547 25.1432 8.10547C27.3313 8.10547 29.6201 8.49609 29.6201 8.49609V13.418H27.0982C24.6137 13.418 23.8389 14.9596 23.8389 16.5413V20.293H29.3857L28.499 26.0742H23.8389V40.05C33.4002 38.5496 40.7139 30.2755 40.7139 20.293Z" fill="#0866FF"/>
					<path fill-rule="evenodd" clip-rule="evenodd" d="M29.3857 20.293H23.8389V16.5413C23.8389 14.9596 24.6137 13.418 27.0982 13.418H29.6201V8.49609C29.6201 8.49609 27.3313 8.10547 25.1432 8.10547C20.5747 8.10547 17.5889 10.8742 17.5889 15.8867V20.293H12.5107V26.0742H17.5889V40.05C18.6071 40.2098 19.6507 40.293 20.7139 40.293C21.777 40.293 22.8206 40.2098 23.8389 40.05V26.0742H28.499L29.3857 20.293Z" fill="white"/>
				</g>
				<defs>
					<clipPath id="clip0_1000_17144">
						<rect width="40" height="40" fill="white" transform="translate(0.713867 0.292969)"/>
					</clipPath>
				</defs>
			</svg>
			<div class="flex align-center justify-center">
				<img src="<?php echo esc_url( KK_FB_WC_PLUGIN_URL . 'assets/ig-icon.png' ); ?>" width="40" height="40" />
			</div>
			<h2>
				<?php
					/* translators: "Facebook", "Instagram" are brand names. Do not translate. */
					esc_html_e( 'Grow your business on Facebook and Instagram', 'kliken-ads-pixel-for-meta' );
				?>
			</h2>
		</div>
	</div>

	<div class="connected">
		<h3>
			<?php
				/* translators: "Social Boost" is product name. Do not translate. */
				esc_html_e( 'Social Boost', 'kliken-ads-pixel-for-meta' );
			?>
		</h3>
		<div class="connected-cards">
			<div class="container">
				<a class="flex" href="<?php echo esc_url( KK_FB_WC_WOOKLIKEN_BASE_URL . 'meta/default.aspx?goto=socialshopnew&acct=' . intval( $settings['account_id'] ) ); ?>">
					<span class="connected-icon">
						<svg width="49" height="48" viewBox="0 0 49 48" fill="none" xmlns="http://www.w3.org/2000/svg">
							<path d="M4.13038 38H10.1304M10.1304 38H16.1304M10.1304 38V32M10.1304 38V44" stroke="black" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round"/>
							<path d="M14.146 4H33.146L42.146 13V38" stroke="black" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round"/>
							<path d="M22.146 44H33.146C34.8028 44 36.146 42.6568 36.146 41V17.4971C36.146 17.1788 36.0196 16.8736 35.7946 16.6485L29.4974 10.3515C29.2724 10.1264 28.9672 10 28.649 10H9.146C7.48914 10 6.146 11.3431 6.146 13V26" stroke="black" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round"/>
							<path d="M28.146 10V16.8C28.146 17.4627 28.6832 18 29.346 18H36.146" stroke="black" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round"/>
						</svg>
					</span>
					<span class="connected-content flex">
						<span class="connected-heading">
							<?php
								/* translators: "Social Boost" is product name. Do not translate. */
								esc_html_e( 'Create a new Social Boost series', 'kliken-ads-pixel-for-meta' );
							?>
						</span>
						<span class="connected-text">
							<?php
								/* translators: "Facebook", "Instagram" are brand names. Do not translate. */
								esc_html_e( 'Effortlessly launch a new AI-driven post series to grow your sales on Facebook and Instagram.', 'kliken-ads-pixel-for-meta' );
							?>
						</span>
					</span>
				</a>
			</div>

			<div class="container">
				<a class="flex" href="<?php echo esc_url( KK_FB_WC_WOOKLIKEN_BASE_URL . 'meta/default.aspx?goto=socialshopmanage&acct=' . intval( $settings['account_id'] ) ); ?>">
					<span class="connected-icon">
						<svg width="49" height="48" viewBox="0 0 49 48" fill="none" xmlns="http://www.w3.org/2000/svg">
							<g clip-path="url(#clip0_3216_140554)">
								<path d="M14.146 4H33.146L42.146 13V38" stroke="black" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round"/>
								<path d="M22.146 44H33.146C34.8028 44 36.146 42.6568 36.146 41V17.4971C36.146 17.1788 36.0196 16.8736 35.7946 16.6485L29.4974 10.3515C29.2724 10.1264 28.9672 10 28.649 10H9.146C7.48914 10 6.146 11.3431 6.146 13V26" stroke="black" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round"/>
								<path d="M28.146 10V16.8C28.146 17.4627 28.6832 18 29.346 18H36.146" stroke="black" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round"/>
								<mask id="mask0_3216_140554" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="27" width="25" height="24">
									<rect x="0.145996" y="27" width="24" height="24" fill="#D9D9D9"/>
								</mask>
								<g mask="url(#mask0_3216_140554)">
									<path d="M5.146 46H6.571L16.346 36.225L14.921 34.8L5.146 44.575V46ZM3.146 48V43.75L16.346 30.575C16.546 30.3917 16.7668 30.25 17.0085 30.15C17.2502 30.05 17.5043 30 17.771 30C18.0377 30 18.296 30.05 18.546 30.15C18.796 30.25 19.0127 30.4 19.196 30.6L20.571 32C20.771 32.1833 20.9168 32.4 21.0085 32.65C21.1002 32.9 21.146 33.15 21.146 33.4C21.146 33.6667 21.1002 33.9208 21.0085 34.1625C20.9168 34.4042 20.771 34.625 20.571 34.825L7.396 48H3.146ZM15.621 35.525L14.921 34.8L16.346 36.225L15.621 35.525Z" fill="black"/>
								</g>
							</g>
							<defs>
								<clipPath id="clip0_3216_140554">
									<rect width="48" height="48" fill="white" transform="translate(0.145996)"/>
								</clipPath>
							</defs>
						</svg>
					</span>
					<span class="connected-content flex">
						<span class="connected-heading">
							<?php esc_html_e( 'Manage existing series', 'kliken-ads-pixel-for-meta' ); ?>
						</span>
						<span class="connected-text">
							<?php
								/* translators: "Social Boost" is product name. Do not translate. */
								esc_html_e( 'Edit, update, or review the performance of your active Social Boost series.', 'kliken-ads-pixel-for-meta' );
							?>
						</span>
					</span>
				</a>
			</div>
		</div>
	</div>

	<div class="connected">
		<h3>
			<?php
				/* translators: "Meta Advantage+" is product name. Do not translate. */
				esc_html_e( 'Meta Advantage+ shopping ads', 'kliken-ads-pixel-for-meta' );
			?>
		</h3>
		<div class="connected-cards">
			<div class="container">
				<a class="flex" href="<?php echo esc_url( KK_FB_WC_WOOKLIKEN_BASE_URL . 'meta/default.aspx?goto=shopnew&acct=' . intval( $settings['account_id'] ) ); ?>">
					<span class="connected-icon">
						<svg width="49" height="49" viewBox="0 0 49 49" fill="none" xmlns="http://www.w3.org/2000/svg">
							<mask id="mask0_3209_140517" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="49" height="49">
								<rect x="0.854004" y="0.539062" width="48" height="48" fill="#D9D9D9"/>
							</mask>
							<g mask="url(#mask0_3209_140517)">
								<path d="M10.7387 41.539C9.9544 41.539 9.27755 41.2543 8.70815 40.6849C8.13875 40.1155 7.85405 39.4386 7.85405 38.6543V10.4237C7.85405 9.63941 8.13875 8.96256 8.70815 8.39316C9.27755 7.82376 9.9544 7.53906 10.7387 7.53906H23.9309V9.80826H10.7387C10.5848 9.80826 10.4438 9.87236 10.3156 10.0006C10.1874 10.1288 10.1233 10.2698 10.1233 10.4237V38.6543C10.1233 38.8082 10.1874 38.9492 10.3156 39.0775C10.4438 39.2057 10.5848 39.2698 10.7387 39.2698H38.9693C39.1232 39.2698 39.2642 39.2057 39.3925 39.0775C39.5207 38.9492 39.5848 38.8082 39.5848 38.6543V25.4622H41.854V38.6543C41.854 39.4386 41.5693 40.1155 40.9999 40.6849C40.4305 41.2543 39.7536 41.539 38.9693 41.539H10.7387ZM33.5848 21.8083V15.8083H27.5848V13.5391H33.5848V7.53906H35.854V13.5391H41.854V15.8083H35.854V21.8083H33.5848Z" fill="black"/>
							</g>
						</svg>
					</span>
					<span class="connected-content flex">
						<span class="connected-heading">
							<?php esc_html_e( 'Create new ad', 'kliken-ads-pixel-for-meta' ); ?>
						</span>
						<span class="connected-text">
							<?php
								/* translators: "Meta Advantage+" is product name. Do not translate. */
								esc_html_e( 'Launch AI-driven Meta Advantage+ shopping ads to boost product visibility and sales.', 'kliken-ads-pixel-for-meta' );
							?>
						</span>
					</span>
				</a>
			</div>

			<div class="container">
				<a class="flex" href="<?php echo esc_url( KK_FB_WC_WOOKLIKEN_BASE_URL . 'meta/default.aspx?goto=shopmanage&acct=' . intval( $settings['account_id'] ) ); ?>">
					<span class="connected-icon">
						<svg width="49" height="49" viewBox="0 0 49 49" fill="none" xmlns="http://www.w3.org/2000/svg">
							<mask id="mask0_3219_140693" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="49" height="49">
								<rect x="0.713867" y="0.539062" width="48" height="48" fill="#D9D9D9"/>
							</mask>
							<g mask="url(#mask0_3219_140693)">
								<path d="M10.5986 41.539C9.81427 41.539 9.13742 41.2543 8.56802 40.6849C7.99862 40.1155 7.71392 39.4386 7.71392 38.6543V10.4237C7.71392 9.63941 7.99862 8.96256 8.56802 8.39316C9.13742 7.82376 9.81427 7.53906 10.5986 7.53906H29.6562L27.387 9.80826H10.5986C10.4447 9.80826 10.3037 9.87236 10.1754 10.0006C10.0472 10.1288 9.98312 10.2698 9.98312 10.4237V38.6543C9.98312 38.8082 10.0472 38.9492 10.1754 39.0775C10.3037 39.2057 10.4447 39.2698 10.5986 39.2698H38.8292C38.983 39.2698 39.1241 39.2057 39.2523 39.0775C39.3805 38.9492 39.4446 38.8082 39.4446 38.6543V21.6582L41.7138 19.389V38.6543C41.7138 39.4386 41.4291 40.1155 40.8597 40.6849C40.2903 41.2543 39.6135 41.539 38.8292 41.539H10.5986Z" fill="black"/>
							</g>
							<mask id="mask1_3219_140693" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="22" y="3" width="24" height="24">
								<rect x="22" y="3" width="24" height="24" fill="#D9D9D9"/>
							</mask>
							<g mask="url(#mask1_3219_140693)">
								<path d="M27 22H28.425L38.2 12.225L36.775 10.8L27 20.575V22ZM25 24V19.75L38.2 6.575C38.4 6.39167 38.6208 6.25 38.8625 6.15C39.1042 6.05 39.3583 6 39.625 6C39.8917 6 40.15 6.05 40.4 6.15C40.65 6.25 40.8667 6.4 41.05 6.6L42.425 8C42.625 8.18333 42.7708 8.4 42.8625 8.65C42.9542 8.9 43 9.15 43 9.4C43 9.66667 42.9542 9.92083 42.8625 10.1625C42.7708 10.4042 42.625 10.625 42.425 10.825L29.25 24H25ZM37.475 11.525L36.775 10.8L38.2 12.225L37.475 11.525Z" fill="black"/>
							</g>
						</svg>
					</span>
					<span class="connected-content flex">
						<span class="connected-heading">
							<?php esc_html_e( 'Manage ads', 'kliken-ads-pixel-for-meta' ); ?>
						</span>
						<span class="connected-text">
							<?php esc_html_e( 'Change an active campaign, purchase one you\'ve built, or reinstate canceled campaigns.', 'kliken-ads-pixel-for-meta' ); ?>
						</span>
					</span>
				</a>
			</div>

		</div>
	</div>


	<div class="connected">
		<h3>
			<?php
				echo esc_html_e( 'Settings', 'kliken-ads-pixel-for-meta' );
			?>
		</h3>
		<div class="connected-cards">
			<div class="container">
				<a class="flex" href="<?php echo esc_url( KK_FB_WC_WOOKLIKEN_BASE_URL . 'meta/default.aspx?goto=account&acct=' . intval( $settings['account_id'] ) ); ?>">
					<span class="connected-icon">
						<svg width="49" height="48" viewBox="0 0 49 48" fill="none" xmlns="http://www.w3.org/2000/svg">
							<mask id="mask0_3209_140523" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="49" height="48">
								<rect x="0.713867" width="48" height="48" fill="#D9D9D9"/>
							</mask>
							<g mask="url(#mask0_3209_140523)">
								<path d="M15.587 33.6115H17.8562V20.7846H15.587V33.6115ZM23.5793 33.6115H25.8485V14.3885H23.5793V33.6115ZM31.5716 33.6115H33.8407V27.0385H31.5716V33.6115ZM10.5986 40.9999C9.81427 40.9999 9.13742 40.7152 8.56802 40.1458C7.99862 39.5764 7.71392 38.8996 7.71392 38.1153V9.88465C7.71392 9.10035 7.99862 8.4235 8.56802 7.8541C9.13742 7.2847 9.81427 7 10.5986 7H38.8292C39.6135 7 40.2903 7.2847 40.8597 7.8541C41.4291 8.4235 41.7138 9.10035 41.7138 9.88465V38.1153C41.7138 38.8996 41.4291 39.5764 40.8597 40.1458C40.2903 40.7152 39.6135 40.9999 38.8292 40.9999H10.5986ZM10.5986 38.7307H38.8292C38.983 38.7307 39.1241 38.6666 39.2523 38.5384C39.3805 38.4102 39.4446 38.2691 39.4446 38.1153V9.88465C39.4446 9.73078 39.3805 9.58974 39.2523 9.4615C39.1241 9.3333 38.983 9.2692 38.8292 9.2692H10.5986C10.4447 9.2692 10.3037 9.3333 10.1754 9.4615C10.0472 9.58974 9.98312 9.73078 9.98312 9.88465V38.1153C9.98312 38.2691 10.0472 38.4102 10.1754 38.5384C10.3037 38.6666 10.4447 38.7307 10.5986 38.7307Z" fill="black"/>
							</g>
						</svg>
					</span>
					<span class="connected-content flex">
						<span class="connected-heading">
							<?php esc_html_e( 'Manage account', 'kliken-ads-pixel-for-meta' ); ?>
						</span>
						<span class="connected-text">
							<?php esc_html_e( 'Update your account settings, billing information, and preferences to keep everything running smoothly.', 'kliken-ads-pixel-for-meta' ); ?>
						</span>
					</span>
				</a>
			</div>
		</div>
	</div>
	<details class="primer advanced-settings">
		<summary>
			<?php esc_html_e( 'Advanced Settings', 'kliken-ads-pixel-for-meta' ); ?>
		</summary>
		<!-- Settings form -->
		<div class="container settings">
			<div class="settings-header flex align-center">
				<h2><?php esc_html_e( 'Settings', 'kliken-ads-pixel-for-meta' ); ?></h2>
				<p>
					<a href="https://intercom.help/kliken/articles/5989948" target="_blank" rel="noopener noreferrer">
						<?php esc_html_e( 'What are these options?', 'kliken-ads-pixel-for-meta' ); ?>
					</a>
				</p>
			</div>

			<form action="<?php menu_page_url( KK_FB_WC_MAIN_PAGE_SLUG ); ?>" method="post" id="kk-settings-form" class="settings-form">
				<?php wp_nonce_field( KK_FB_WC_ACTION_SAVE_SETTINGS ); ?>
				<fieldset>
					<div class="flex align-center">
						<label for="account_id"><?php esc_html_e( 'Account Id', 'kliken-ads-pixel-for-meta' ); ?></label>
						<input type="text" name="account_id" id="account_id" disabled
								value="<?php echo esc_attr( $settings['account_id'] ); ?>" />
					</div>

					<div class="flex align-center">
						<label for="app_token"><?php esc_html_e( 'Application Token', 'kliken-ads-pixel-for-meta' ); ?></label>
						<input type="text" name="app_token" id="app_token" disabled
								value="<?php echo esc_attr( $settings['app_token'] ?? '' ); ?>" />
					</div>

					<div class="flex align-center fb-token">
						<label for="facebook_token">
							<?php
								/* translators: Facebook is product name. Do not translate. */
								esc_html_e( 'Facebook Verification Token', 'kliken-ads-pixel-for-meta' );
							?>
						</label>
						<input type="text" name="facebook_token" id="facebook_token" disabled
								value="<?php echo esc_attr( $settings['facebook_token'] ?? '' ); ?>" />
					</div>
				</fieldset>

				<button type="button" name="edit" id="edit-kk-settings" class="edit-settings edit">
					<?php esc_html_e( 'Edit Settings', 'kliken-ads-pixel-for-meta' ); ?>
				</button>

				<button type="submit" name="save" id="save-kk-settings" class="edit-settings save">
					<span class="save-text">
						<?php esc_html_e( 'Save Changes', 'kliken-ads-pixel-for-meta' ); ?>
					</span>
					<svg width="41" height="40" viewBox="0 0 41 40" fill="none" xmlns="http://www.w3.org/2000/svg">
						<mask id="mask0_1182_3077" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="41" height="40">
						<rect x="0.5" width="40" height="40" fill="white"/>
						</mask>
						<g mask="url(#mask0_1182_3077)">
						<path d="M20.5 36.6667C18.2223 36.6667 16.0695 36.2292 14.0417 35.3542C12.0139 34.4792 10.2431 33.2848 8.72921 31.7709C7.21532 30.257 6.02087 28.4862 5.14587 26.4584C4.27087 24.4306 3.83337 22.2778 3.83337 20C3.83337 17.6945 4.27087 15.5348 5.14587 13.5209C6.02087 11.507 7.21532 9.7431 8.72921 8.22921C10.2431 6.71532 12.0139 5.52087 14.0417 4.64587C16.0695 3.77087 18.2223 3.33337 20.5 3.33337C20.9723 3.33337 21.3681 3.4931 21.6875 3.81254C22.007 4.13199 22.1667 4.52782 22.1667 5.00004C22.1667 5.47226 22.007 5.8681 21.6875 6.18754C21.3681 6.50698 20.9723 6.66671 20.5 6.66671C16.8056 6.66671 13.6598 7.96532 11.0625 10.5625C8.46532 13.1598 7.16671 16.3056 7.16671 20C7.16671 23.6945 8.46532 26.8403 11.0625 29.4375C13.6598 32.0348 16.8056 33.3334 20.5 33.3334C24.1945 33.3334 27.3403 32.0348 29.9375 29.4375C32.5348 26.8403 33.8334 23.6945 33.8334 20C33.8334 19.5278 33.9931 19.132 34.3125 18.8125C34.632 18.4931 35.0278 18.3334 35.5 18.3334C35.9723 18.3334 36.3681 18.4931 36.6875 18.8125C37.007 19.132 37.1667 19.5278 37.1667 20C37.1667 22.2778 36.7292 24.4306 35.8542 26.4584C34.9792 28.4862 33.7848 30.257 32.2709 31.7709C30.757 33.2848 28.9931 34.4792 26.9792 35.3542C24.9653 36.2292 22.8056 36.6667 20.5 36.6667Z" fill="white"/>
						</g>
					</svg>
				</button>

				<button type="reset" id="cancel-edit-kk-settings" class="cancel">Cancel</button>
			</form>

			<?php if ( intval( $settings['account_id'] ) > 0 && ! empty( $settings['app_token'] ) ) : ?>
				<a href="<?php echo esc_url( \Kliken\FbWcPlugin\Helper::build_authorization_url( $settings['account_id'], $settings['app_token'] ) ); ?>">
					<button type="button" id="authorize-api-access" class="primary-button">
						<?php esc_html_e( 'Authorize API Access', 'kliken-ads-pixel-for-meta' ); ?>
					</button>
				</a>
			<?php endif; ?>
		</div>
	</details>
</div>
