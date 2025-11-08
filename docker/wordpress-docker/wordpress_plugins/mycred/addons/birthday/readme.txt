=== myCred Birthdays ===
Contributors: mycred, wpexpertsio
Tags: achievements, myCred, birthday, reward, birthdays
Requires at least: 4.8
Tested up to: 6.2
Stable tag: 1.0.4
Requires PHP: 7.0
License: GPLv2 or later
License URI: https://www.gnu.org/licenses/gpl-2.0.html

== Description ==

This plugin gives you access to the myCred Birthdays hook which you can setup to reward / deduct points from your users on their birthday! Supports BuddyPress or websites where the users date of birth is stored as a custom user meta.

To prevent abuse, users can only get birthday points once each year. This means your users can change their date of birth if they want but it will not trigger new points.

The hook will check for birthdays on the first page request each morning. If you think the hook has missed a day, you can always trigger a new check by saving the hooks settings. Clicking on the Save button will force the hook to check for birthdays on the next page load.

= BuddyPress Setup =
If you use BuddyPress profiles, you can create a custom profile field where users enter their date of birth. You can name the field anything you like and use any format. The only requirement is that the field type is set to “Date selector”. This will ensure all fields are properly formatted.

= WordPress User Meta Setup =
WordPress and a vast majority of plugins store user details as custom user meta in your database. If you have a field setup or your plugin provides a field, enter the meta key’s id. The dates must be stores formatted using Year Month Day Y-m-d. You can select to store times as well but this will be ignored.

= Plugin Requirements =

* [myCred 1.8+](https://wordpress.org/plugins/mycred/)
* WordPress 5.0+
* PHP 5.3+

= More myCred Freebies Integrations = 

* [myCred H5P](https://mycred.me/store/mycred-h5p)
* [myCred Credly](https://mycred.me/store/mycred-credly)
* [myCred - Learndash](https://www.mycred.me/store/mycred-learndash/)
* [LifterLMS Plugin Integration with myCred ](https://www.mycred.me/store/mycred-lifterlms-integration)
* [myCred BP Group Leaderboards](https://www.mycred.me/store/mycred-bp-group-leaderboards)
* [myCred for Event Espresso 4.6+](https://www.mycred.me/store/mycred-for-event-espresso-4)
* [myCred for Wp-Pro-Quiz](https://mycred.me/store/mycred-for-wp-pro-quiz/)
* [myCred for Rating Form](https://www.mycred.me/store/mycred-for-rating-form)
* [myCred for WP-PostViews](https://www.mycred.me/store/mycred-for-wp-postviews)
* [myCred for TotalPoll](https://mycred.me/store/mycred-for-totalpoll)
* [myCred Gutenberg](https://www.mycred.me/store/mycred-gutenberg)
* [myCred for Events Manager Pro](https://www.mycred.me/store/mycred-for-events-manager-pro)
* [myCred for BuddyPress Compliments](https://www.mycred.me/store/mycred-for-buddypress-compliments)
* [myCred Retro](https://www.mycred.me/store/mycred-retro)
* [myCred for Courseware](https://www.mycred.me/store/mycred-for-courseware)
* [myCred for GD Star Rating](https://www.mycred.me/store/mycred-for-gd-star-rating)
* [myCred for BuddyPress Links](https://mycred.me/store/mycred-for-buddypress-links)
* [myCred for BP Album and BP Gallery](https://mycred.me/store/mycred-for-bp-album-bp-gallery)
* [myCred Elementor](https://mycred.me/store/mycred-elementor/)


= DOCUMENTATION AND SUPPORT =
For more information visit our **[Documentation Page](https://www.mycred.me/store/mycred-birthdays/)**.

== Installation ==

1. Go to Plugins > Add New.
2. Under Search, type myCred Birthdays
3. Find myCred Birthdays and click Install Now to install it
4. If successful, click Activate Plugin to activate it and you are ready to go.

== Changelog ==

= 1.0.4 =
New – Compatible with WordPress 6.2

= 1.0.3 =
Improvement – Code Optimization

= 1.0.2 =
Improvement – Get plugin updates from wordpress.org

= 1.0.1 =
UPDATE – Updated the hook settings styling.

= 1.0 =
Initial release