<?php
if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

class Widget_Mycred_Total_Balance extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Total Balance widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_total_balance';
    }

    /**
     * Get widget title.
     *
     * Retrieve Total Balance widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Total Balance', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Total Balance widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Total Balance widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Total Points widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Total Balance Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'user_id', [
            'label' => __('User ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'current',
            'description' => __('Option to return a specific users balance. Use "current" to show the current users total balance.', 'mycred')
                ]
        );

        $this->add_control(
                'point_type', [
            'label' => __('Point Type(s)', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'all',
            'description' => __('Either a single point type key, or "all" for adding up all existing point types or a comma separated list of point type keys. No empty spaces allowed!', 'mycred')
                ]
        );
        $this->add_control(
                'unformatted', [
            'label' => __('Unformatted', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'description' => __('Do you want to just return the amount without any HTML elements?', 'mycred')
                ]
        );

        $this->add_control(
                'total', [
            'label' => __('Total', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'description' => __('Do you want to show the total balance?', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render Total Balance widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['user_id'])) {
            $this->add_render_attribute('shortcode', 'user_id', $settings['user_id']);
        }
        if (!empty($settings['point_type'])) {
            if ($settings['point_type'] == 'all') {
                $point_types = mycred_get_types();
                $this->add_render_attribute('shortcode', 'types', implode(',', array_flip($point_types)));
            } else {
                $this->add_render_attribute('shortcode', 'types', $settings['point_type']);
            }
        }
        $raw = isset($settings['raw']) && $settings['raw'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'raw', $raw);

        $total = $settings['total'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'total', $total);
        
        $unformatted = $settings['unformatted'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'unformatted', $unformatted);
        
        
        $shortcode = do_shortcode('[mycred_total_balance ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>
        <?php
    }

}

class Widget_Mycred_Total_Pts extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Total Pts widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_total_points';
    }

    /**
     * Get widget title.
     *
     * Retrieve Total Points widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Total Points', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Total Points widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Total Points widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Total Points widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Total Points Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'point_type', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'default' => 'mycred_default',
            'description' => __('The point type to add up.', 'mycred')
                ]
        );
        $this->add_control(
                'reference', [
            'label' => __('Reference', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => sprintf(__('Option to add up points based on a single reference or a comma separated list of references. %s.', 'mycred'), sprintf('<a href="http://codex.mycred.me/chapter-vi/log-references/" target="_blank">%s</a>', __('List of references', 'mycred')))
                ]
        );
        $this->add_control(
                'ref_id', [
            'label' => __('Reference ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to filter results based on reference ID. Leave empty if not used.', 'mycred')
                ]
        );
        $this->add_control(
                'user_id', [
            'label' => __('User ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to add up points for a specific user. Use "current" for the current user viewing the shortcode or leave empty to add up points for everyone. Must be used in combination with "Reference" and/or "Reference ID" above.', 'mycred')
                ]
        );

        $this->add_control(
                'formatted', [
            'label' => __('Formatted', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'yes',
            'description' => __('Option to show results formatted with prefix / suffix (1) or in plain format (0).', 'mycred')
                ]
        );

        $this->end_controls_section();
    }

    /**
     * Render Total Points widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();
        if (!empty($settings['point_type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['point_type']);
        }
        if (!empty($settings['reference'])) {
            $this->add_render_attribute('shortcode', 'ref', $settings['reference']);
        }
        if (!empty($settings['ref_id'])) {
            $this->add_render_attribute('shortcode', 'ref_id', $settings['ref_id']);
        }
        if (!empty($settings['user_id'])) {
            $this->add_render_attribute('shortcode', 'user_id', $settings['user_id']);
        }
        $formatted = $settings['formatted'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'formatted', $formatted);

        $shortcode = do_shortcode('[mycred_total_points ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_History extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Total History widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_history';
    }

    /**
     * Get widget title.
     *
     * Retrieve Total History widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('My History', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Total History widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Total History widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Total History widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $time = array(
            __('Show All', 'mycred') => '',
            __('Today', 'mycred') => 'today',
            __('Yesterday', 'mycred') => 'yesterday',
            __('This Week', 'mycred') => 'thisweek',
            __('This Month', 'mycred') => 'thismonth'
        );


        $this->start_controls_section(
                'content_section', [
            'label' => __('My History Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'user_id', [
            'label' => __('User ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to show a specific users history. Use "current" to show the current users history or leave empty to show everyones history.', 'mycred')
                ]
        );


        $this->add_control(
                'number', [
            'label' => __('Number of Entries', 'mycred'),
            'type' => \Elementor\Controls_Manager::NUMBER,
            'default' => 10,
            'description' => __('The number of entries to show per page. Defaults to 10.', 'mycred')
                ]
        );
        $this->add_control(
                'time', [
            'label' => __('Time', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => array_flip($time),
            'description' => __('Option to return entries for specific time period.', 'mycred')
                ]
        );
        $this->add_control(
                'reference', [
            'label' => __('Reference', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to only show log entries for the specified reference. Can be a single reference or a comma separated list of references (without any empty spaces).', 'mycred')
                ]
        );
        $this->add_control(
                'order', [
            'label' => __('Order', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_order(),
            'default' => 'DESC',
            'description' => __('Order of the log entries. Either ASC for ascending or DESC for descending.', 'mycred')
                ]
        );
        $this->add_control(
                'show_user', [
            'label' => __('Show User Column?', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
                ]
        );
        $this->add_control(
                'show_nav', [
            'label' => __('Show Navigation?', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'description' => __('Option to show the pagination navigation bar. (Requires 1.7)', 'mycred')
                ]
        );
        $this->add_control(
                'inlinenav', [
            'label' => __('Inline Navigation?', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'description' => __('If your theme is rendering the navigation vertically instead of horizontally, make sure you select "Yes" here.', 'mycred')
                ]
        );

        $this->add_control(
                'login', [
            'label' => __('Login Message', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Message to show a logged out user trying to view this shortcode. Leave empty if you want visitors to see the log as well.', 'mycred')
                ]
        );

        $this->add_control(
                'point_type', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'default' => 'mycred_default',
            'description' => __('The point type to add up.', 'mycred')
                ]
        );

        $this->add_control(
                'pagination', [
            'label' => __('Pagination', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 10,
            'description' => __('The number of pagination links to show. Ignored if you set to hide navigation above. (Requires 1.7)', 'mycred')
                ]
        );
        $this->end_controls_section();
    }

    /**
     * Render Total History widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['point_type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['point_type']);
        }

        if (!empty($settings['reference'])) {
            $this->add_render_attribute('shortcode', 'ref', $settings['reference']);
        }


        if (!empty($settings['pagination'])) {
            $this->add_render_attribute('shortcode', 'pagination', $settings['pagination']);
        }

        if (!empty($settings['user_id'])) {
            $this->add_render_attribute('shortcode', 'user_id', $settings['user_id']);
        }
        if (!empty($settings['order'])) {
            $this->add_render_attribute('shortcode', 'order', $settings['order']);
        }
        if (!empty($settings['login'])) {
            $this->add_render_attribute('shortcode', 'login', $settings['login']);
        }
        if (!empty($settings['time'])) {
            $this->add_render_attribute('shortcode', 'time', $settings['time']);
        }
        if (!empty($settings['number'])) {
            $this->add_render_attribute('shortcode', 'number', $settings['number']);
        }


        $show_user = $settings['show_user'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'show_user', $show_user);

        $show_nav = $settings['show_nav'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'show_nav', $show_nav);

        $inlinenav = $settings['inlinenav'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'inlinenav', $inlinenav);

        $shortcode = do_shortcode('[mycred_history ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Total_Since extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Total Since widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_total_since';
    }

    /**
     * Get widget title.
     *
     * Retrieve Total Since widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Total Since', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Total Since widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Total Since widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Total Since widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Total Since Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'from', [
            'label' => __('From', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'today',
            'description' => __('Option to set from when we should start adding up points. Accepts: "today" for start of today, a UNIX timestamp or a well formatted date. See PHPs strtotime for further information on available options.', 'mycred')
                ]
        );
        $this->add_control(
                'until', [
            'label' => __('Until', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'now',
            'description' => __('Option to set what time to stop counting. Accepts: "now" for now, a UNIX timestamp or a well formatted date. See PHPs strtotime for further information on available options.', 'mycred')
                ]
        );

        $this->add_control(
                'point_type', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'default' => 'mycred_default',
            'description' => __('The point type to add up.', 'mycred')
                ]
        );

        $this->add_control(
                'reference', [
            'label' => __('Reference', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => sprintf(__('Option to filter results based on a reference. %s.', 'mycred'), sprintf('<a href="http://codex.mycred.me/chapter-vi/log-references/" target="_blank">%s</a>', __('List of references', 'mycred')))
                ]
        );

        $this->add_control(
                'user_id', [
            'label' => __('User ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to show a specific users history. Use "current" to show the current users history or leave empty to show everyones history.', 'mycred')
                ]
        );

        $this->add_control(
                'formatted', [
            'label' => __('Formatted', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'yes',
            'description' => __('Option to show results formatted with prefix / suffix (1) or in plain format (0).', 'mycred')
                ]
        );

        $this->end_controls_section();
    }

    /**
     * Render Total Since widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['point_type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['point_type']);
        }

        if (!empty($settings['reference'])) {
            $this->add_render_attribute('shortcode', 'ref', $settings['reference']);
        }

        if (!empty($settings['user_id'])) {
            $this->add_render_attribute('shortcode', 'user_id', $settings['user_id']);
        }

        if (!empty($settings['from'])) {
            $this->add_render_attribute('shortcode', 'from', $settings['from']);
        }

        if (!empty($settings['until'])) {
            $this->add_render_attribute('shortcode', 'until', $settings['until']);
        }

        $formatted = $settings['formatted'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'formatted', $formatted);

        $shortcode = do_shortcode('[mycred_total_since ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Leaderboard extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Leaderboard widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_leaderboard';
    }

    /**
     * Get widget title.
     *
     * Retrieve Leaderboard widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Leaderboard', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Leaderboard widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Leaderboard widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Leaderboard widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Leaderboard Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'number', [
            'label' => __('Number of Users', 'mycred'),
            'type' => \Elementor\Controls_Manager::NUMBER,
            'default' => '25',
            'description' => __('The maximum number of users to include in the leaderboard.', 'mycred')
                ]
        );

        $this->add_control(
                'order', [
            'label' => __('Order', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_order(),
            'default' => 'DESC',
            'description' => __('Order of the leaderboard. Either ASC for ascending or DESC for descending order.', 'mycred')
                ]
        );



        $this->add_control(
                'offset', [
            'label' => __('Offset', 'mycred'),
            'type' => \Elementor\Controls_Manager::NUMBER,
            'default' => '0',
            'description' => __('Option to offset the results. Use zero for no offset.', 'mycred')
                ]
        );


        $this->add_control(
                'point_type', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'default' => 'mycred_default',
            'description' => __('The point type to add up.', 'mycred')
                ]
        );

        $this->add_control(
                'based_on', [
            'label' => __('Based On', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'balance',
            'description' => __('Use "balance" for a leaderboard based on your users balances. Otherwise use the reference you want to base the leaderboard on. Can not be empty! List of %s.', 'mycred', sprintf('<a href="http://codex.mycred.me/chapter-vi/log-references/" target="_blank">%s</a>', __('List of references', 'mycred')))
                ]
        );
        $this->add_control(
                'total', [
            'label' => __('Total', 'mycred'),
            'type' => \Elementor\Controls_Manager::NUMBER,
            'default' => '0',
            'description' => __('Select to use users total balance (1) instead of their current balance (0). Added in 1.7.5.', 'mycred')
                ]
        );
        $this->add_control(
                'wrap', [
            'label' => __('Row Wrap Element', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('The HTML element you want to use for each row in the leaderboard. Will default to list element (li).', 'mycred')
                ]
        );
        $this->add_control(
                'template', [
            'label' => __('Row Template', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '#%position% %user_profile_link% %cred_f%',
            'description' => __('The template to use for each row.', 'mycred')
                ]
        );
        $this->add_control(
                'nothing', [
            'label' => __('No Results', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Message to show when there are no results to show.', 'mycred')
                ]
        );

        $this->add_control(
                'current', [
            'label' => __('Current Users Position', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'no',
            'description' => __('Select if you want to include the current users position in the leaderboard.', 'mycred')
                ]
        );
        $this->add_control(
                'exclude_zero', [
            'label' => __('Exclude Zero Balance', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'yes',
            'description' => __('Only applicable for leaderboards based on balance. By default zero balances are ignored but you can select to override this.', 'mycred')
                ]
        );
        $this->add_control(
                'timeframe', [
            'label' => __('Timeframe', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to limit the leaderboard to a specific timeframe. Leave empty for all time, use "today" for todays leaderboard, "this-week" for this weeks leaderboard, "this-month" for this months leaderboard or enter a date to calculate from (until today). Date must be formatted either YYYY-MM-DD or MM/DD/YYYY. (Requires 1.7)', 'mycred')
                ]
        );

        $this->end_controls_section();
    }

    /**
     * Render Leaderboard widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();



        if (!empty($settings['number'])) {
            $this->add_render_attribute('shortcode', 'number', $settings['number']);
        }


        if (!empty($settings['order'])) {
            $this->add_render_attribute('shortcode', 'order', $settings['order']);
        }

        if (!empty($settings['offset'])) {
            $this->add_render_attribute('shortcode', 'offset', $settings['offset']);
        }

        if (!empty($settings['point_type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['point_type']);
        }

        if (!empty($settings['based_on'])) {
            $this->add_render_attribute('shortcode', 'based_on', $settings['based_on']);
        }

        if (!empty($settings['total'])) {
            $this->add_render_attribute('shortcode', 'total', $settings['total']);
        }

        if (!empty($settings['wrap'])) {
            $this->add_render_attribute('shortcode', 'wrap', $settings['wrap']);
        }


        if (!empty($settings['template'])) {
            $this->add_render_attribute('shortcode', 'template', $settings['template']);
        }

        if (!empty($settings['nothing'])) {
            $this->add_render_attribute('shortcode', 'nothing', $settings['nothing']);
        }

        $current = $settings['current'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'current', $current);

        $exclude_zero = $settings['exclude_zero'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'exclude_zero', $exclude_zero);

        if (!empty($settings['timeframe'])) {
            $this->add_render_attribute('shortcode', 'timeframe', $settings['timeframe']);
        }


        $shortcode = do_shortcode('[mycred_leaderboard ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Best_User extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Best User widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_best_user';
    }

    /**
     * Get widget title.
     *
     * Retrieve Best User widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Best User', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Best User widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Best User widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Best User widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Best User Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'ref', [
            'label' => __('Reference(s)', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => sprintf(__('Comma separated list of references to add up. %s.', 'mycred'), sprintf('<a href="http://codex.mycred.me/chapter-vi/log-references/" target="_blank">%s</a>', __('List of references', 'mycred')))
                ]
        );


        $this->add_control(
                'from', [
            'label' => __('From', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to sum up results from a specific date. Can be used in combination with "Until". Leave empty if not used.', 'mycred')
                ]
        );


        $this->add_control(
                'until', [
            'label' => __('Until', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to sum up results until a specific date. Can be used in combination with "From". Leave empty if not used.', 'mycred')
                ]
        );


        $this->add_control(
                'types', [
            'label' => __('Point Type(s)', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'mycred_default',
            'description' => __('The point type to add up.', 'mycred')
                ]
        );

        $this->add_control(
                'nothing', [
            'label' => __('No Results', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Information to show if no results were found. No HTML allowed.', 'mycred')
                ]
        );


        $this->add_control(
                'order', [
            'label' => __('Order', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_order(),
            'default' => 'DESC',
            'description' => __('Order of the results.', 'mycred')
                ]
        );



        $this->add_control(
                'avatar', [
            'label' => __('Avatar Size', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 50,
            'description' => __('The size of the avatar, if the %avatar% template tag is used in your template.', 'mycred')
                ]
        );
        $this->add_control(
                'content', [
            'label' => __('Template', 'mycred'),
            'type' => \Elementor\Controls_Manager::WYSIWYG,
            'default' => '<div class="mycred-best-user">%avatar%<h4>%display_name%</h4></div>'
                ]
        );

        $this->end_controls_section();
    }

    /**
     * Render Best User widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();


        if (!empty($settings['ref'])) {
            $this->add_render_attribute('shortcode', 'ref', $settings['ref']);
        }

        if (!empty($settings['order'])) {
            $this->add_render_attribute('shortcode', 'order', $settings['order']);
        }

        if (!empty($settings['from'])) {
            $this->add_render_attribute('shortcode', 'from', $settings['from']);
        }
        if (!empty($settings['until'])) {
            $this->add_render_attribute('shortcode', 'until', $settings['until']);
        }

        if (!empty($settings['types'])) {
            $this->add_render_attribute('shortcode', 'types', $settings['types']);
        }

        if (!empty($settings['nothing'])) {
            $this->add_render_attribute('shortcode', 'nothing', $settings['nothing']);
        }

        if (!empty($settings['avatar'])) {
            $this->add_render_attribute('shortcode', 'avatar', $settings['avatar']);
        }

        $html = '[mycred_best_user ' . $this->get_render_attribute_string('shortcode') . ']' . $settings['content'] . '[/mycred_best_user]';
        $shortcode = do_shortcode($html);
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Exchange extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Exchange widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_exchange';
    }

    /**
     * Get widget title.
     *
     * Retrieve Exchange widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Exchange', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Exchange widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Exchange widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Exchange widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Exchange Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'from', [
            'label' => __('Exchange From', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type to exchange from.', 'mycred')
                ]
        );

        $this->add_control(
                'to', [
            'label' => __('Exchange To', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type to exchange to.', 'mycred')
                ]
        );


        $this->add_control(
                'rate', [
            'label' => __('Exchange Rate', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 1,
            'description' => __('The exchange rate.', 'mycred')
                ]
        );


        $this->add_control(
                'min', [
            'label' => __('Minimum', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 1,
            'description' => __('Minimum amount that a user must select to exchange. Use zero for no limit.', 'mycred')
                ]
        );



        $this->add_control(
                'button', [
            'label' => __('Button Label', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'Exchange',
            'description' => __('The submit button label', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render Exchange widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();


        if (!empty($settings['from'])) {
            $this->add_render_attribute('shortcode', 'from', $settings['from']);
        }

        if (!empty($settings['to'])) {
            $this->add_render_attribute('shortcode', 'to', $settings['to']);
        }

        if (!empty($settings['rate'])) {
            $this->add_render_attribute('shortcode', 'rate', $settings['rate']);
        }

        if (!empty($settings['min'])) {
            $this->add_render_attribute('shortcode', 'min', $settings['min']);
        }

        if (!empty($settings['button'])) {
            $this->add_render_attribute('shortcode', 'button', $settings['button']);
        }

        $shortcode = do_shortcode('[mycred_exchange ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Link extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Link widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_link';
    }

    /**
     * Get widget title.
     *
     * Retrieve Link widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Link', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Link widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Link widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Link widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Link Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'amount', [
            'label' => __('Amount', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 0,
            'description' => __('Amount of points for clicking on this link. Use zero to give the amount you set in your "Points for clicking on links" hook settings.', 'mycred')
                ]
        );


        $this->add_control(
                'ctype', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type you want to give.', 'mycred')
                ]
        );



        $this->add_control(
                'href', [
            'label' => __('HREF', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Required href attribute for the anchor element.', 'mycred')
                ]
        );
        $this->add_control(
                'id', [
            'label' => __('ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional id attribute for the anchor element.', 'mycred')
                ]
        );


        $this->add_control(
                'rel', [
            'label' => __('Rel', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional rel attribute for the anchor element.', 'mycred')
                ]
        );



        $this->add_control(
                'title', [
            'label' => __('Title', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional title attribute for the anchor element.', 'mycred')
                ]
        );

        $this->add_control(
                'target', [
            'label' => __('Target', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional target attribute for the anchor element.', 'mycred')
                ]
        );

        $this->add_control(
                'style', [
            'label' => __('Style', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional style attribute for the anchor element.', 'mycred')
                ]
        );
        $this->add_control(
                'class', [
            'label' => __('Class', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional class attribute for the anchor element.', 'mycred')
                ]
        );
        $this->add_control(
                'hreflang', [
            'label' => __('HREFLANG', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional hreflang attribute for the anchor element.', 'mycred')
                ]
        );
        $this->add_control(
                'media', [
            'label' => __('Media', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional media attribute for the anchor element.', 'mycred')
                ]
        );
        $this->add_control(
                'type', [
            'label' => __('Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional type attribute for the anchor element.', 'mycred')
                ]
        );
        $this->add_control(
                'onclick', [
            'label' => __('OnClick', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional onclick attribute.', 'mycred')
                ]
        );
        $this->add_control(
                'content', [
            'label' => __('Link Title', 'mycred'),
            'type' => \Elementor\Controls_Manager::WYSIWYG,
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render Link widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['amount'])) {
            $this->add_render_attribute('shortcode', 'amount', $settings['amount']);
        }

        if (!empty($settings['ctype'])) {
            $this->add_render_attribute('shortcode', 'ctype', $settings['ctype']);
        }


        if (!empty($settings['href'])) {
            $safe_href = esc_url($settings['href']);
            $this->add_render_attribute('shortcode', 'href', $safe_href);
        }

        if (!empty($settings['id'])) {
            $this->add_render_attribute('shortcode', 'id', $settings['id']);
        }

        if (!empty($settings['rel'])) {
            $this->add_render_attribute('shortcode', 'rel', $settings['rel']);
        }
        if (!empty($settings['title'])) {
            $this->add_render_attribute('shortcode', 'title', $settings['title']);
        }

        if (!empty($settings['target'])) {
            $this->add_render_attribute('shortcode', 'target', $settings['target']);
        }
        if (!empty($settings['style'])) {
            $this->add_render_attribute('shortcode', 'style', $settings['style']);
        }
        if (!empty($settings['class'])) {
            $this->add_render_attribute('shortcode', 'class', $settings['class']);
        }
        if (!empty($settings['hreflang'])) {
            $this->add_render_attribute('shortcode', 'hreflang', $settings['hreflang']);
        }
        if (!empty($settings['media'])) {
            $this->add_render_attribute('shortcode', 'media', $settings['media']);
        }
        if (!empty($settings['type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['type']);
        }
        if (!empty($settings['onclick'])) {
            $this->add_render_attribute('shortcode', 'onclick', $settings['onclick']);
        }

        $html = '[mycred_link ' . $this->get_render_attribute_string('shortcode') . ']' . $settings['content'] . '[/mycred_link]';
        $shortcode = do_shortcode($html);
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Give extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Give widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_give';
    }

    /**
     * Get widget title.
     *
     * Retrieve Give widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Give Points', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Give widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Give widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Give widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Give Points Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'amount', [
            'label' => __('Amount', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Required amount to give the user when this shortcode fires.', 'mycred')
                ]
        );

        $this->add_control(
                'user_id', [
            'label' => __('User ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'current',
            'description' => __('Option to award a specific user. Use "current" to use five points to the user that views the shortcode. Can not be empty.', 'mycred')
                ]
        );


        $this->add_control(
                'log', [
            'label' => __('Log Entry', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('The log entry template. Can not be empty. Does not support HTML elements.', 'mycred')
                ]
        );

        $this->add_control(
                'ref', [
            'label' => __('Reference', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'gift',
            'description' => __('A reference to log this transaction under. Can not be empty and must be a lowercase string. Instead of empty spaces please use underscores.', 'mycred')
                ]
        );

        $this->add_control(
                'limit', [
            'label' => __('Limit', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 0,
            'description' => __('Optional limit the number of times a user can gain points from this shortcode. Use zero for no limit.', 'mycred_vc')
                ]
        );

        $this->add_control(
                'type', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type you want to give.', 'mycred')
                ]
        );

        $this->add_control(
                'content', [
            'label' => __('Content', 'mycred'),
            'type' => \Elementor\Controls_Manager::WYSIWYG,
            'description' => __('Content to show visitors viewing this shortcode. Leave empty to show nothing.', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render Give widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();


        if (!empty($settings['amount'])) {
            $this->add_render_attribute('shortcode', 'amount', $settings['amount']);
        }

        if (!empty($settings['user_id'])) {
            $this->add_render_attribute('shortcode', 'user_id', $settings['user_id']);
        }

        if (!empty($settings['log'])) {
            $this->add_render_attribute('shortcode', 'log', $settings['log']);
        }

        if (!empty($settings['ref'])) {
            $this->add_render_attribute('shortcode', 'ref', $settings['ref']);
        }

        if (!empty($settings['limit'])) {
            $this->add_render_attribute('shortcode', 'limit', $settings['limit']);
        }
        if (!empty($settings['type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['type']);
        }

        $html = '[mycred_give ' . $this->get_render_attribute_string('shortcode') . ']' . $settings['content'] . '[/mycred_give]';
        $shortcode = do_shortcode($html);
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Affiliate_Id extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Affiliate ID widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_affiliate_id';
    }

    /**
     * Get widget title.
     *
     * Retrieve Affiliate ID widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Affiliate ID', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Affiliate ID widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Affiliate ID widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Affiliate ID widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Affiliate Id Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'type', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type you want to show the affiliate link for.', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render Affiliate ID widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['type']);
        }


        $shortcode = do_shortcode('[mycred_affiliate_id ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Affiliate_Link extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Affiliate Link widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_affiliate_link';
    }

    /**
     * Get widget title.
     *
     * Retrieve Affiliate Link widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Affiliate Link', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Affiliate Link widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Affiliate Link widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Affiliate Link widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Affiliate Link Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'url', [
            'label' => __('URL', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('The URL to attach the current users affiliate ID to. No ID is attached for visitors that are not logged in.', 'mycred')
                ]
        );
        $this->add_control(
                'type', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type you want to show the affiliate link for.', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render Affiliate Link widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['url'])) {
            $this->add_render_attribute('shortcode', 'url', $settings['url']);
        }

        if (!empty($settings['type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['type']);
        }

        $shortcode = do_shortcode('[mycred_affiliate_link ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Hook_Table extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Hook Table widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_hook_table';
    }

    /**
     * Get widget title.
     *
     * Retrieve Hook Table widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Hook Table', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Hook Table widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Hook Table widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Hook Table widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Hook Table Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'type', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type to show hooks for.', 'mycred')
                ]
        );

        $this->add_control(
                'gains', [
            'label' => __('Show Gains', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'yes',
            'description' => __('Show ways to gain points (yes) or ways to lose points (no).', 'mycred')
                ]
        );

        $this->add_control(
                'post', [
            'label' => __('Post Related Template Tags', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '-post-',
            'description' => __('Text to replace all post related template tags with.', 'mycred')
                ]
        );

        $this->add_control(
                'user', [
            'label' => __('User Related Template Tags', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '-user-',
            'description' => __('Text to replace all user related template tags with.', 'mycred')
                ]
        );

        $this->add_control(
                'comment', [
            'label' => __('Comment Related Template Tags', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '-comment-',
            'description' => __('Text to replace all comment related template tags with.', 'mycred')
                ]
        );
        $this->add_control(
                'amount', [
            'label' => __('Amount Related Template Tags', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Text to replace all amount related template tags with.', 'mycred')
                ]
        );
        $this->add_control(
                'nothing', [
            'label' => __('No Hooks', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'No instances found for this point type',
            'description' => __('Text to show when there are no active hooks for the selected point type.', 'mycred')
                ]
        );

        $this->end_controls_section();
    }

    /**
     * Render Hook Table widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['type']);
        }

        $gains = $settings['gains'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'gains', $gains);

        if (!empty($settings['user'])) {
            $this->add_render_attribute('shortcode', 'user', $settings['user']);
        }

        if (!empty($settings['post'])) {
            $this->add_render_attribute('shortcode', 'post', $settings['post']);
        }

        if (!empty($settings['comment'])) {
            $this->add_render_attribute('shortcode', 'comment', $settings['comment']);
        }

        if (!empty($settings['amount'])) {
            $this->add_render_attribute('shortcode', 'amount', $settings['amount']);
        }

        if (!empty($settings['nothing'])) {
            $this->add_render_attribute('shortcode', 'nothing', $settings['nothing']);
        }


        $shortcode = do_shortcode('[mycred_hook_table ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_My_Balance extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve My Balance widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_my_balance';
    }

    /**
     * Get widget title.
     *
     * Retrieve My Balance widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('My Balance', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve My Balance widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the My Balance widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register My Balance widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('My Balance Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'user_id', [
            'label' => __('User ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'current',
            'description' => __('The users balance you want to show. Use "current" to show the user who is viewing the shortcode. Can not be empty.', 'mycred')
                ]
        );

        $this->add_control(
                'title', [
            'label' => __('Title', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Optional title to add before the balance.', 'mycred')
                ]
        );
        $this->add_control(
                'title_el', [
            'label' => __('Title Element', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('The HTML element to wrap around the title. Leave empty if not used.', 'mycred')
                ]
        );


        $this->add_control(
                'balance_el', [
            'label' => __('Balance Element', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('The HTML element to wrap around the balance. Leave empty to hide wrapping element.', 'mycred')
                ]
        );

        $this->add_control(
                'wrapper', [
            'label' => __('Use Wrappers', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'yes',
            'description' => __('Select if you want to wrap the balance for styling or just return the balance amount.', 'mycred')
                ]
        );
        $this->add_control(
                'formatted', [
            'label' => __('Format Balance', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'yes',
            'description' => __('Select if you want to format the balance amount with prefix / suffix or show just the amount. (Requires 1.7)', 'mycred')
                ]
        );

        $this->add_control(
                'type', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type to show hooks for.', 'mycred')
                ]
        );

        $this->add_control(
                'content', [
            'label' => __('Visitors Message', 'mycred'),
            'type' => \Elementor\Controls_Manager::WYSIWYG,
            'description' => __('Optional message to show when the shortcode is viewed by a visitor that is not logged in.', 'mycred')
                ]
        );
        $this->end_controls_section();
    }

    /**
     * Render My Balance widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['user_id'])) {
            $this->add_render_attribute('shortcode', 'user_id', $settings['user_id']);
        }

        if (!empty($settings['title'])) {
            $this->add_render_attribute('shortcode', 'title', $settings['title']);
        }

        if (!empty($settings['title_el'])) {
            $this->add_render_attribute('shortcode', 'title_el', $settings['title_el']);
        }

        if (!empty($settings['balance_el'])) {
            $this->add_render_attribute('shortcode', 'balance_el', $settings['balance_el']);
        }

        $wrapper = $settings['wrapper'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'wrapper', $wrapper);

        $formatted = $settings['formatted'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'formatted', $formatted);

        if (!empty($settings['type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['type']);
        }
        $html = '[mycred_my_balance ' . $this->get_render_attribute_string('shortcode') . ']' . $settings['content'] . '[/mycred_my_balance]';
        $shortcode = do_shortcode($html);
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Video extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Video widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_video';
    }

    /**
     * Get widget title.
     *
     * Retrieve Video widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Watch Video', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Video widget icon.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget icon.
     */
    public function get_icon() {
        return 'fa fa-user';
    }

    /**
     * Get widget categories.
     *
     * Retrieve the list of categories the Video widget belongs to.
     *
     * @since 1.0.0
     * @access public
     *
     * @return array Widget categories.
     */
    public function get_categories() {
        return ['mycred'];
    }

    /**
     * Register Video widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $logics = array(
            __('Play - Award points as soon as video starts playing', 'mycred_vc') => 'play',
            __('Full - Award points only if user watches the entire video', 'mycred_vc') => 'full',
            __('Interval - Award points every x seconds watched', 'mycred_vc') => 'interval'
        );

        $this->start_controls_section(
                'content_section', [
            'label' => __('Watch Video Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'id', [
            'label' => __('Video ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Required video ID to show. No URls or embed codes! Just the video ID.', 'mycred')
                ]
        );

        $this->add_control(
                'width', [
            'label' => __('Width', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 560,
            'description' => __('Width of the Iframe', 'mycred')
                ]
        );

        $this->add_control(
                'height', [
            'label' => __('Height', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 315,
            'description' => __('Height of the Iframe', 'mycred_vc')
                ]
        );

        $this->add_control(
                'amount', [
            'label' => __('Amount', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('The amount of points to give users for watching this video. Leave empty to use your default settings.', 'mycred')
                ]
        );

        $this->add_control(
                'logic', [
            'label' => __('Logic', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => array_flip($logics),
            'description' => __('The award logic to use.', 'mycred_vc')
                ]
        );


        $this->add_control(
                'interval', [
            'label' => __('Interval', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Number of seconds that a user must watch to get points. Only use this if you have set "Logic" to "Interval".', 'mycred')
                ]
        );


        $this->add_control(
                'type', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type you want to be sent.', 'mycred')
                ]
        );



        $this->end_controls_section();
    }

    /**
     * Render Video widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();


        if (!empty($settings['amount'])) {
            $this->add_render_attribute('shortcode', 'amount', $settings['amount']);
        }

        if (!empty($settings['id'])) {
            $this->add_render_attribute('shortcode', 'id', $settings['id']);
        }

        if (!empty($settings['logic'])) {
            $this->add_render_attribute('shortcode', 'logic', $settings['logic']);
        }
        if (!empty($settings['interval'])) {
            $this->add_render_attribute('shortcode', 'interval', $settings['interval']);
        }

        if (!empty($settings['width'])) {
            $this->add_render_attribute('shortcode', 'width', $settings['width']);
        }

        if (!empty($settings['height'])) {
            $this->add_render_attribute('shortcode', 'height', $settings['height']);
        }

        if (!empty($settings['type'])) {
            $this->add_render_attribute('shortcode', 'type', $settings['type']);
        }

        $html = '[mycred_video ' . $this->get_render_attribute_string('shortcode') . ']';

        $shortcode = do_shortcode($html);
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

