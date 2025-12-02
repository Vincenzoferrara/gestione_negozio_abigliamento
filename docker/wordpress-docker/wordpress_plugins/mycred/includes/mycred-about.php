<?php
if ( ! defined( 'myCRED_VERSION' ) ) exit;

/**
 * myCRED About Page Header
 * @since 1.3.2
 * @version 1.4
 */
function mycred_about_header() {

	$name = mycred_label();

?>
<style type="text/css">
#mycred-welcome {
    color: #555;
    padding-top: 110px;
}
#mycred-welcome .container {
    margin: 0 auto;
    max-width: 720px;
    padding: 0;
}
#mycred-welcome .intro {
    background-color: #fff;
    border: 2px solid #e1e1e1;
    border-radius: 2px;
    margin-bottom: 30px;
    position: relative;
    padding-top: 40px;
}
#mycred-welcome .intro .mycred-logo {
	background: url('<?php echo esc_url( plugins_url( 'assets/images/mycred-icon.png', myCRED_THIS ) ); ?>') no-repeat center center; 
	background-size: 95px;
	display: block;
    margin: auto;
    box-shadow: none;

    background-color: #fff;
    border: 2px solid #e1e1e1;
    border-radius: 50%;
    height: 110px;
    width: 110px;
    padding: 18px 14px 0 14px;
    position: absolute;
    top: -58px;
    left: 50%;
    margin-left: -55px;
}
#mycred-welcome img {
    max-width: 100%;
    height: auto;
}
#mycred-welcome .block {
    padding: 40px;
}
#mycred-welcome h1 {
    color: #222;
    font-size: 24px;
    text-align: center;
    margin: 0 0 16px 0;
}
#mycred-welcome h6 {
    font-size: 16px;
    font-weight: 400;
    line-height: 1.6;
    text-align: center;
    margin: 0;
}
#mycred-welcome .intro .button-wrap {
    margin-top: 25px;
}

#mycred-welcome .button-wrap {
    max-width: 590px;
    margin: 0 auto 0 auto;
}
.mycred-clear:before {
    content: " ";
    display: table;
}
#mycred-welcome .button-wrap .left {
    float: left;
    width: 50%;
    padding-right: 20px;
}
#mycred-welcome .button-wrap .center {
    width: 50%;
    margin: 0 auto;
    padding-right: 20px;
}
.mycred-admin-page .mycred-btn-orange {
    background-color: #9852f1;
    color: #fff;
}

.mycred-admin-page .mycred-btn-lg {
    font-size: 16px;
    font-weight: 600;
    padding: 16px 28px;
}
.mycred-admin-page .mycred-btn-block {
    display: block;
    width: 100%;
}
.mycred-admin-page .mycred-btn {
    border: 1px;
    border-style: solid;
    border-radius: 3px;
    cursor: pointer;
    display: inline-block;
    margin: 0;
    text-decoration: none;
    text-align: center;
    vertical-align: middle;
    white-space: nowrap;
    box-shadow: none;
}
#mycred-welcome .button-wrap .right {
    float: right;
    width: 50%;
    padding-left: 20px;
}
.mycred-admin-page .mycred-btn-grey {
    background-color: #eee;
    border-color: #ccc;
    color: #666;
}
.mycred-clear:after {
    clear: both;
    content: " ";
    display: table;
}
#mycred-welcome .features {
    background-color: #fff;
    border: 2px solid #e1e1e1;
    border-bottom: 0;
    border-radius: 2px 2px 0 0;
    position: relative;
    padding-top: 20px;
    padding-bottom: 20px;
}
#mycred-welcome .features .feature-list {
    margin-top: 60px;
}
#mycred-welcome .features .feature-block.first {
    padding-right: 20px;
    clear: both;
}
#mycred-welcome .features .feature-block {
    float: left;
    width: 50%;
    padding-bottom: 35px;
    overflow: auto;
}
#mycred-welcome *, #mycred-welcome *::before, #mycred-welcome *::after {
    /* -webkit-box-sizing: border-box; */
    -moz-box-sizing: border-box;
    box-sizing: border-box;
}
#mycred-welcome .features .feature-block img {
    float: left;
    max-width: 46px;
}
#mycred-welcome .features .feature-block h5 {
    margin-left: 68px;
}

#mycred-welcome h5 {
    color: #222;
    font-size: 16px;
    margin: 0 0 8px 0;
}
#mycred-welcome .features .feature-block p {
    margin: 0;
    margin-left: 68px;
}

#mycred-welcome p {
    font-size: 14px;
    margin: 0 0 20px 0;
}
#mycred-welcome .features .feature-block.last {
    padding-left: 20px;
}
#mycred-welcome .features .button-wrap {
    margin-top: 25px;
    text-align: center;
}
#mycred-welcome .upgrade-cta {
    background-color: #000;
    border: 2px solid #e1e1e1;
    border-top: 0;
    border-bottom: 0;
    color: #fff;
}
#mycred-welcome .upgrade-cta .left {
    float: left;
    width: 66.666666%;
    padding-right: 20px;
}
#mycred-welcome .upgrade-cta h2 {
    color: #fff;
    font-size: 20px;
    margin: 0 0 30px 0;
}
#mycred-welcome .upgrade-cta ul {
    display: -ms-flex;
    display: -webkit-flex;
    display: flex;
    -webkit-flex-wrap: wrap;
    flex-wrap: wrap;
    font-size: 15px;
    margin: 0;
    padding: 0;
}
#mycred-welcome .upgrade-cta ul li {
    display: block;
    width: 55%;
    margin: 0 0 8px 0;
    padding: 0;
}
#mycred-welcome .upgrade-cta ul li .dashicons {
    color: #2a9b39;
    margin-right: 5px;
}
.dashicons-yes:before {
    content: "\f147";
}
#mycred-welcome .upgrade-cta .right {
    float: right;
    width: 33.333333%;
    padding: 20px 0 0 20px;
    text-align: center;
}
#mycred-welcome .upgrade-cta .right h2 {
    text-align: center;
    margin: 0;
}

#mycred-welcome .upgrade-cta h2 {
    color: #fff;
    font-size: 20px;
    margin: 0 0 30px 0;
}
#mycred-welcome .upgrade-cta .right h2 span {
    display: inline-block;
    border-bottom: 1px solid #555;
    padding: 0 15px 12px;
}
#mycred-welcome .upgrade-cta .right .price {
    padding: 26px 0;
}
#mycred-welcome .upgrade-cta .right .price .amount {
    font-size: 48px;
    font-weight: 600;
    position: relative;
    display: inline-block;
}
#mycred-welcome .upgrade-cta .right .price .amount:before {
    content: '$';
    position: absolute;
    top: -8px;
    left: -16px;
    font-size: 18px;
}
#mycred-welcome .upgrade-cta .right .price .term {
    font-size: 12px;
    display: inline-block;
}
#mycred-welcome .testimonials {
    background-color: #fff;
    border: 2px solid #e1e1e1;
    border-top: 0;
    padding: 20px 0;
}
#mycred-welcome .testimonials .testimonial-block {
    margin: 50px 0 0 0;
}
#mycred-welcome .testimonials .testimonial-block img {
    float: left;
    max-width: 50px;
}
#mycred-welcome .testimonials .testimonial-block p {
    font-size: 14px;
    margin: 0 0 12px 95px;
}
#mycred-welcome .testimonials .testimonial-block p:last-of-type {
    margin-bottom: 0;
}
b, strong {
    font-weight: 600;
	font-style: italic;
}
#mycred-welcome .footer {
    background-color: #f9f9f9;
    border: 2px solid #e1e1e1;
    border-top: 0;
    border-radius: 0 0 2px 2px;
}
.mycred-admin-page .mycred-footer-btn {
    margin-left: 60%;
}
.clear {
    clear: both;
}
#mycred-welcome .mycred-change-log {
	padding: 32px;
	margin-top: 32px;
	background-color: #fff;
    border: 2px solid #e1e1e1;
    border-top: 0;
    padding: 20px 0;
}
#mycred-welcome .mycred-change-log ul{
	list-style: inside;
}
.members {
    padding-bottom: 25px;
}

</style>
<div class="mycred-admin-page">
<div id="mycred-welcome" class="lite">

			<div class="container">

				<div class="intro">

					<div class="mycred-logo">
					</div>

					<div class="block">
					<h1><?php printf( esc_html__( 'Welcome to myCred', 'mycred' ) ); ?></h1>
						<h6>You now have myCred - The most powerful points management system for WordPress. Build and manage range of digital rewards, including points, ranks, and badges to drive growth on your site.
                        </h6>
					</div>
<?php

}

/**
 * myCRED About Page Footer
 * @since 1.3.2
 * @version 1.2
 */
function mycred_about_footer() {

?>
<?php 
if ( !is_mycred_ready() ) {
?>
<div class="footer">

<div class="block mycred-clear">

	<div class="button-wrap mycred-clear">
		<div class="left">
			<a href="<?php echo esc_url( admin_url( 'plugins.php?page=' . MYCRED_SLUG . '-setup&mycred_tour_guide=1' ) ); ?>" id="first_setup" onclick="startTour()" class="mycred-btn mycred-btn-block mycred-btn-lg mycred-btn-orange mycred-footer-btn">
			Setup myCred
			</a>
		
		</div>
	</div>

</div>

</div><!-- /.footer -->
<?php
}
?>
<p style="margin: 15px; text-align: center;">A big Thank You to everyone who helped support myCred!</p>
	
<?php

}

/**
 * About myCRED Page
 * @since 1.3.2
 * @version 1.4
 */
function mycred_about_page() {

?>
<?php mycred_render_admin_header(); ?>

<div class="mycred-welcome">
		<div class="mycred-intro">
			<?php 

			$name = mycred_label();

			mycred_about_header(); 

			?>
	
				<img src="<?php echo esc_url( plugins_url( 'assets/images/about/welcome.png', myCRED_THIS ) ); ?>" alt="Welcome" class="video-thumbnail">

			<div class="block">
				
				<div class="button-wrap mycred-clear">
					<div class="left">
						<?php 
						if ( !is_mycred_ready() ) {
						?>
							<a href="<?php echo esc_url( admin_url( 'plugins.php?page=' . MYCRED_SLUG . '-setup&mycred_tour_guide=1' ) ); ?>" id="first_setup" onclick="startTour()" class="mycred-btn mycred-btn-block mycred-btn-lg mycred-btn-orange">
								Setup myCred
							</a>
						<?php
						}
						?>
					</div>
					<div class="<?php echo ( is_mycred_ready() ? 'center' : 'right' ); ?>">
						<a href="https://codex.mycred.me/?utm_source=plugin&utm_medium=about_page_doc" class="mycred-btn mycred-btn-block mycred-btn-lg mycred-btn-grey" target="_blank" rel="noopener noreferrer">
							Documentation
						</a>
					</div>
				</div>
			</div>

		</div><!-- /.intro -->

			<div class="features">

				<div class="block">

					<h1>myCred Features &amp; Addons</h1>

					<div class="feature-list mycred-clear">

						<div class="feature-block first">
							<img src="<?php echo esc_url( plugins_url( 'assets/images/about/account.png', myCRED_THIS ) ); ?>">
							<h5>WooCommerce Plus</h5>
							<p>Let users pay with points, combine partial payments, and reward WooCommerce purchases automatically.</p>
						</div>

						<div class="feature-block last">
							<img src="<?php echo esc_url( plugins_url( 'assets/images/about/points-management.png', myCRED_THIS ) ); ?>">
							<h5>Badgr (Credly Integration)</h5>
							<p>Award verifiable digital badges for user achievements that sync with external platforms like Credly or Badgr.</p>
						</div>

						<div class="feature-block first">
							<img src="<?php echo esc_url( plugins_url( 'assets/images/about/automatic-points.png', myCRED_THIS ) ); ?>">
							<h5>BuyCred Paystack Gateway</h5>
							<p>Allow users to purchase points securely using Paystack or other supported payment gateways.</p>
						</div>

						<div class="feature-block last">
							<img src="<?php echo esc_url( plugins_url( 'assets/images/about/multi-points.png', myCRED_THIS ) ); ?>">
							<h5>cashCred PayPal / Stripe</h5>
							<p>Enable users to withdraw their earned points as real cash through PayPal or Stripe.</p>
						</div>

						<div class="feature-block first">
							<img src="<?php echo esc_url( plugins_url( 'assets/images/about/convert-points.png', myCRED_THIS ) ); ?>">
							<h5>Points Cap</h5>
							<p>Limit how many points users can earn within a set period to prevent farming or abuse.</p>
						</div>

						<div class="feature-block last">
							<img src="<?php echo esc_url( plugins_url( 'assets/images/about/multi-site-support.png', myCRED_THIS ) ); ?>">
							<h5>Time-Based Reward</h5>
							<p>Automatically grant points for continuous engagement or time spent on your site.</p>
						</div>

						<div class="feature-block first">
							<img src="<?php echo esc_url( plugins_url( 'assets/images/about/leaderboards.png', myCRED_THIS ) ); ?>">
							<h5>LevelCred</h5>
							<p>Unlock new user levels or ranks based on total points, achievements, or milestones.</p>
						</div>

						<div class="feature-block last">
							<img src="<?php echo esc_url( plugins_url( 'assets/images/about/badges.png', myCRED_THIS ) ); ?>">
							<h5>BP Group Leaderboards</h5>
							<p>Show competitive leaderboards inside BuddyPress groups based on user points or activity.</p>
						</div>

						<div class="feature-block first">
							<img src="<?php echo esc_url( plugins_url( 'assets/images/about/buy-points.png', myCRED_THIS ) ); ?>">
							<h5>Pending Points</h5>
							<p>Hold earned points for admin review before they’re officially added to a user’s balance.</p>
						</div>

						<div class="feature-block last">
							<img src="<?php echo esc_url( plugins_url( 'assets/images/about/sell-content.png', myCRED_THIS ) ); ?>">
							<h5>Sell Content</h5>
							<p>Creates a flexible soft paywall that requires users to spend earned or purchased points for premium access.</p>
						</div>

					</div>

					<div class="button-wrap">
						<a href="https://mycred.me/pricing/?utm_source=plugin&utm_medium=about_page_addons" class="mycred-btn mycred-btn-lg mycred-btn-grey" rel="noopener noreferrer" target="_blank">
							More Addons
						</a>
					</div>

				</div>

			</div><!-- /.features -->

			<div class="upgrade-cta upgrade">

				<div class="block mycred-clear">

					<div class="left">
						<h2>Choose Value-filled myCred Plans!</h2>
						<div class="members">Join 10,000+ WordPress site owners to boost user engagement and convert casual users into repeated buyers. Save 75% on all LIFETIME Plans.</div>
						<ul>
							<li><span class="dashicons dashicons-yes"></span> Premium Addons</li>
							<li><span class="dashicons dashicons-yes"></span> WooCommerce Integration</li>
							<li><span class="dashicons dashicons-yes"></span> Priority Technical Support</li>
							<li><span class="dashicons dashicons-yes"></span> Regular security updates</li>
						</ul>
					</div>

					<div class="right">
						<h2><span>Starting from</span></h2>
						<div class="price">
							<span class="amount">99</span><br>
							<span class="term">per year</span>
						</div>
						<a href="https://mycred.me/pricing/?utm_source=plugin&utm_medium=about_page_plans" rel="noopener noreferrer" target="_blank" class="mycred-btn mycred-btn-block mycred-btn-lg mycred-btn-orange mycred-upgrade-modal">
							Pricing Plans
						</a>
					</div>
				</div>
			</div><!-- upgrade-cta -->
			<div class="testimonials upgrade">

				<div class="block">

					<h1>Testimonials</h1>

					<div class="testimonial-block mycred-clear">
						<img src="<?php echo esc_url( plugins_url( 'assets/images/about/56826.png', myCRED_THIS ) ); ?>">
						<p>myCred is pretty solid WordPress plugin. You can do almost anything with it.	myCred offers a great developer codex along with hooks, and filters. The versatile collection of addons is just amazing.</p>
						<p><strong>Wooegg</strong></p>
					</div>

					<div class="testimonial-block mycred-clear">
						<img src="<?php echo esc_url( plugins_url( 'assets/images/about/56826.png', myCRED_THIS ) ); ?>">
						<p>MyCred might be free but the add-ons it offers are absolutely incredible! myCred is the best points system for WordPress, period.</p>
						<p><strong>Rongenius</strong></p>
					</div>
					<div class="testimonial-block mycred-clear">
						<img src="<?php echo esc_url( plugins_url( 'assets/images/about/56826.png', myCRED_THIS ) ); ?>">
						<p>myCred is highly optimized and there are a lot of functions and short codes available to customize its structure. Special congratulations to its creators!</p>
						<p><strong>Miladesmaili</strong></p>
					</div>

				</div>

			</div><!-- /.testimonials -->


			<?php mycred_about_footer(); ?>
</div><!-- /#mycred-welcome -->
<?php

}
