<?php
if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

class Widget_Mycred_Email_Subscriptions extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Email Subscriptions widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_email_subscriptions';
    }

    /**
     * Get widget title.
     *
     * Retrieve Email Subscriptions widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Email Subscriptions', 'mycred');
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
     * Retrieve the list of categories the Email Subscriptions widget belongs to.
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
     * Register Email Subscriptions widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Email Subscriptions Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'success', [
            'label' => __('Success', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'Settings Saved',
            'description' => __('Message to show when settings have been changed.', 'mycred')
                ]
        );

        $this->end_controls_section();
    }

    /**
     * Render Email Subscriptions widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['success'])) {
            $this->add_render_attribute('shortcode', 'success', $settings['success']);
        }

        $shortcode = do_shortcode('[mycred_email_subscriptions ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}
