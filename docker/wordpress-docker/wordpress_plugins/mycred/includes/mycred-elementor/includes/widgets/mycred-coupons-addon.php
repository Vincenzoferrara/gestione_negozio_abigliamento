<?php
if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

class Widget_Mycred_Load_Coupon extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Coupon widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_load_coupon';
    }

    /**
     * Get widget title.
     *
     * Retrieve Coupon widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Load Coupon', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Coupon widget icon.
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
     * Retrieve the list of categories the Coupon widget belongs to.
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
     * Register Coupon widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {
        $this->start_controls_section(
                'content_section', [
            'label' => __('Load Coupons Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'label', [
            'label' => __('Label', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'Coupon',
            'description' => __('The coupon label. Can not be empty.', 'mycred')
                ]
        );

        $this->add_control(
                'button', [
            'label' => __('Button', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => 'Apply Coupon',
            'description' => __('The form submit buttons label.', 'mycred')
                ]
        );

        $this->add_control(
                'placeholder', [
            'label' => __('Placeholder', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('The placeholder label for the coupon field.', 'mycred')
                ]
        );
    }

    /**
     * Render Coupon widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['button'])) {
            $this->add_render_attribute('shortcode', 'button', $settings['button']);
        }
        if (!empty($settings['label'])) {
            $this->add_render_attribute('shortcode', 'label', $settings['label']);
        }
        if (!empty($settings['placeholder'])) {
            $this->add_render_attribute('shortcode', 'placeholder', $settings['placeholder']);
        }

        $shortcode = do_shortcode('[mycred_load_coupon ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}
