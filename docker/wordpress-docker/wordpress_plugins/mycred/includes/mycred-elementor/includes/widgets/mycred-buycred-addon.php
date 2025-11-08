<?php
if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

class Widget_Mycred_Buy extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Buy widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_buy';
    }

    /**
     * Get widget title.
     *
     * Retrieve Buy widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Buy', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Buy widget icon.
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
     * Retrieve the list of categories the Buy widget belongs to.
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
     * Register Buy widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $buycred = new myCRED_buyCRED_Module();

        $gateways = array();

        foreach ($buycred->get() as $gateway_id => $gateway) {
            $gateways[$gateway['title']] = $gateway_id;
        }

        $this->start_controls_section(
                'content_section', [
            'label' => __('Buy Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );

        $this->add_control(
                'content', [
            'label' => __('Link Title', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('The purchase link title. If not set, the anchor element will be rendered but will be empty. Only leave this entry if you intend to style the element and need this to be empty!', 'mycred')
                ]
        );


        $this->add_control(
                'gateway', [
            'label' => __('Gateway', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => array_flip($gateways),
            'description' => __('Required payment gateway to use for this purchase.', 'mycred')
                ]
        );

        $this->add_control(
                'amount', [
            'label' => __('Amount', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Amount of points to purchase.', 'mycred')
                ]
        );


        $this->add_control(
                'gift_to', [
            'label' => __('Gift to', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('By default, the current user will receive the purchased amount. Use "author" to gift purchases to the post author or a specific users ID. Leave empty if not used!', 'mycred')
                ]
        );

        $this->add_control(
                'class', [
            'label' => __('Class', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Optional class to add to the purchase link element.', 'mycred')
                ]
        );
        $this->add_control(
                'login', [
            'label' => __('Login Message', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Optional message to show logged out users viewing this shortcode. Nothing is returned if left empty.', 'mycred')
                ]
        );


        $this->add_control(
                'ctype', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type the user gets. Should only be used if you want to sell a custom point type.', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render Buy widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['gateway'])) {
            $this->add_render_attribute('shortcode', 'gateway', $settings['gateway']);
        }
        if (!empty($settings['amount'])) {
            $this->add_render_attribute('shortcode', 'amount', $settings['amount']);
        }

        if (!empty($settings['gift_to'])) {
            $this->add_render_attribute('shortcode', 'gift_to', $settings['gift_to']);
        }

        if (!empty($settings['class'])) {
            $this->add_render_attribute('shortcode', 'class', $settings['class']);
        }

        if (!empty($settings['login'])) {
            $this->add_render_attribute('shortcode', 'login', $settings['login']);
        }
        if (!empty($settings['ctype'])) {
            $this->add_render_attribute('shortcode', 'ctype', $settings['ctype']);
        }
        $html = '[mycred_buy ' . $this->get_render_attribute_string('shortcode') . ']' . $settings['content'] . '[/mycred_buy]';

        $shortcode = do_shortcode($html);
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}

class Widget_Mycred_Buy_Form extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Buy Form widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_buy_form';
    }

    /**
     * Get widget title.
     *
     * Retrieve Buy Form widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Buy Form', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Buy Form widget icon.
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
     * Retrieve the list of categories the Buy Form widget belongs to.
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
     * Register Buy Form widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Buy Form Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'gateway', [
            'label' => __('Gateway', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Enter the gateway ID to enforce the use of a specific gateway or leave empty to let users choose.', 'mycred')
                ]
        );

        $this->add_control(
                'amount', [
            'label' => __('Amount', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('This can either be a set amount for users to buy, a comma separated list of amounts that users can choose from or left empty in which case the user decides how much they want to buy.', 'mycred')
                ]
        );

        $this->add_control(
                'button', [
            'label' => __('Button Label', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('The label for the form submit button.', 'mycred')
                ]
        );


        $this->add_control(
                'gift_to', [
            'label' => __('Gift to', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('By default, the current user will receive the purchased amount. Use "author" to gift purchases to the post author or a specific users ID. Leave empty if not used!', 'mycred')
                ]
        );
        $this->add_control(
                'gift_by', [
            'label' => __('Gift By', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
                ]
        );

        $this->add_control(
                'ctype', [
            'label' => __('Point Type', 'mycred'),
            'type' => \Elementor\Controls_Manager::SELECT,
            'options' => mycred_get_cred_types(),
            'description' => __('The point type you want to show.', 'mycred')
                ]
        );
        $this->add_control(
                'inline', [
            'label' => __('Inline', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'description' => __('Controls if the form should be inline (1) or not (0). Requires themes using the Bootstrap framework.', 'mycred')
                ]
        );

        $this->end_controls_section();
    }

    /**
     * Render Buy Form widget output on the frontend.
     *
     * Written in PHP and used to generate the final HTML.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function render() {

        $settings = $this->get_settings_for_display();

        if (!empty($settings['gateway'])) {
            $this->add_render_attribute('shortcode', 'gateway', $settings['gateway']);
        }
        if (!empty($settings['amount'])) {
            $this->add_render_attribute('shortcode', 'amount', $settings['amount']);
        }

        if (!empty($settings['gift_to'])) {
            $this->add_render_attribute('shortcode', 'gift_to', $settings['gift_to']);
        }
        if (!empty($settings['gift_by'])) {
            $this->add_render_attribute('shortcode', 'gift_to', $settings['gift_to']);
        }

        if (!empty($settings['button'])) {
            $this->add_render_attribute('shortcode', 'button', $settings['button']);
        }
        if (!empty($settings['ctype'])) {
            $this->add_render_attribute('shortcode', 'ctype', $settings['ctype']);
        }

        $inline = $settings['inline'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'inline', $inline);


        $shortcode = do_shortcode('[mycred_buy_form ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}
