<?php
if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

class Widget_Mycred_My_Badges extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve My Badges widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_my_badges';
    }

    /**
     * Get widget title.
     *
     * Retrieve My Badges widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('My Badges', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve My Badges widget icon.
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
     * Retrieve the list of categories the My Badges widget belongs to.
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
     * Register My Badges widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('My Badges Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'show', [
            'label' => __('Show', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => array(
                'all' => __('All Badges', 'mycred'),
                'earned' => __('Earned Badges', 'mycred')
            ),
            'default' => 'all',
            'description' => __('Select if you want to show only badges that a user has earned or all badges.', 'mycred')
                ]
        );

        $this->add_control(
                'title', [
            'label' => __('Badge title', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'no',
            'description' => __('Option to show Badge Title', 'mycred')
                ]
        );

        $this->add_control(
                'width', [
            'label' => __('Width', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Badge image width.', 'mycred')
                ]
        );

        $this->add_control(
                'height', [
            'label' => __('Height', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Badge image height.', 'mycred')
                ]
        );


        $this->add_control(
                'user_id', [
            'label' => __('User ID', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'no',
            'description' => __('Option to show a specific users badges.', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render My Badges widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['show'])) {
            $this->add_render_attribute('shortcode', 'show', $settings['show']);
        }

        $title = $settings['title'] == 'yes' ? 1 : 0;
        if (!empty($settings['title'])) {
            $this->add_render_attribute('shortcode', 'title', $title);
        }

        if (!empty($settings['width'])) {
            $this->add_render_attribute('shortcode', 'width', $settings['width']);
        }

        if (!empty($settings['height'])) {
            $this->add_render_attribute('shortcode', 'height', $settings['height']);
        }

        if (!empty($settings['user_id'])) {
            $this->add_render_attribute('shortcode', 'user_id', $settings['user_id']);
        }

        $shortcode = do_shortcode('[mycred_my_badges ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode;  ?></div>

        <?php
    }

}

class Widget_Mycred_Badges extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve All Badges widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_badges';
    }

    /**
     * Get widget title.
     *
     * Retrieve All Badges widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('All Badges', 'mycred');
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
     * Retrieve the list of categories the All Badges widget belongs to.
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
     * Register All Badges widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('All Badges Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'width', [
            'label' => __('Image Width', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Badge image width.', 'mycred')
                ]
        );

        $this->add_control(
                'height', [
            'label' => __('Image Height', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Badge image height.', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render All Badges widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['width'])) {
            $this->add_render_attribute('shortcode', 'width', $settings['width']);
        }

        if (!empty($settings['height'])) {
            $this->add_render_attribute('shortcode', 'height', $settings['height']);
        }

        $shortcode = do_shortcode('[mycred_badges ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}
