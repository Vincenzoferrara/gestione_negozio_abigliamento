<?php
if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

class Widget_Mycred_Transfer extends \Elementor\Widget_Base {

    /**
     * Get widget name.
     *
     * Retrieve Transfer widget name.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget name.
     */
    public function get_name() {
        return 'mycred_transfer';
    }

    /**
     * Get widget title.
     *
     * Retrieve Transfer widget title.
     *
     * @since 1.0.0
     * @access public
     *
     * @return string Widget title.
     */
    public function get_title() {
        return __('Transfer', 'mycred');
    }

    /**
     * Get widget icon.
     *
     * Retrieve Transfer widget icon.
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
     * Retrieve the list of categories the Transfer widget belongs to.
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
     * Register Transfer widget controls.
     *
     * Adds different input fields to allow the user to change and customize the widget settings.
     *
     * @since 1.0.0
     * @access protected
     */
    protected function _register_controls() {

        $this->start_controls_section(
                'content_section', [
            'label' => __('Transfer Settings', 'mycred'),
            'tab' => \Elementor\Controls_Manager::TAB_CONTENT,
                ]
        );


        $this->add_control(
                'button', [
            'label' => __('Button Label', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('The submit transfer button label. Leave empty to use the default label you set in your settings.', 'mycred')
                ]
        );


        $this->add_control(
                'pay_to', [
            'label' => __('Recipient', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to pre-select a specific user to transfer points to. If left empty, the user must nominate the recipient.', 'mycred')
                ]
        );

        $this->add_control(
                'show_balance', [
            'label' => __('Show Balance', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'no',
            'description' => __('Option to include the current users balance.', 'mycred')
                ]
        );

        $this->add_control(
                'show_limit', [
            'label' => __('Show Limit', 'mycred'),
            'type' => \Elementor\Controls_Manager::SWITCHER,
            'default' => 'no',
            'description' => __('Option to include the current users remaining transfer limit.', 'mycred_vc')
                ]
        );


        $this->add_control(
                'types', [
            'label' => __('Point Types', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('A comma separated list of point type keys that users can transfer. You can also just use one specific key to lock transfers to this point type only. Otherwise leave this field empty to use the default point type.', 'mycred')
                ]
        );

        $this->add_control(
                'excluded', [
            'label' => __('Excluded message', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Message to show when the user attempting to make a transfer has been set to be "Excluded" from using myCRED.', 'mycred')
                ]
        );

        $this->add_control(
                'amount', [
            'label' => __('Amount', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Option to pre-set the amount a user must transfer. Leave empty for the user to nominate the amount.', 'mycred')
                ]
        );

        $this->add_control(
                'placeholder', [
            'label' => __('Placeholder', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('Optional text to show in the recipient field via the placeholder attribute.', 'mycred')
                ]
        );

        $this->add_control(
                'ref', [
            'label' => __('Reference', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'default' => '',
            'description' => __('By default, transfers are logged with "transfer" as reference. You can change this to a unique lowercase word like "donation" or "charity_fund_raiser" to separate transfers made with this shortcode from others.', 'mycred')
                ]
        );

        $this->add_control(
                'recipient_label', [
            'label' => __('Recipient Label', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to change the label shown above the recipient field.', 'mycred')
                ]
        );

        $this->add_control(
                'amount_label', [
            'label' => __('Amount Label', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to change the label shown above the amount field.', 'mycred')
                ]
        );

        $this->add_control(
                'balance_label', [
            'label' => __('Balance Label', 'mycred'),
            'type' => \Elementor\Controls_Manager::TEXT,
            'description' => __('Option to change the label shown above the point type selection. Only used if more then one point type is setup to be transferable.', 'mycred')
                ]
        );


        $this->end_controls_section();
    }

    /**
     * Render Transfer widget output on the frontend.
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
        if (!empty($settings['pay_to'])) {
            $this->add_render_attribute('shortcode', 'pay_to', $settings['pay_to']);
        }
        if (!empty($settings['placeholder'])) {
            $this->add_render_attribute('shortcode', 'placeholder', $settings['placeholder']);
        }
        if (!empty($settings['balance_label'])) {
            $this->add_render_attribute('shortcode', 'balance_label', $settings['balance_label']);
        }

        if (!empty($settings['ref'])) {
            $this->add_render_attribute('shortcode', 'ref', $settings['ref']);
        }
        if (!empty($settings['amount'])) {
            $this->add_render_attribute('shortcode', 'amount', $settings['amount']);
        }
        if (!empty($settings['types'])) {
            $this->add_render_attribute('shortcode', 'types', $settings['types']);
        }
        if (!empty($settings['excluded'])) {
            $this->add_render_attribute('shortcode', 'excluded', $settings['excluded']);
        }
        if (!empty($settings['recipient_label'])) {
            $this->add_render_attribute('shortcode', 'recipient_label', $settings['recipient_label']);
        }
        if (!empty($settings['amount_label'])) {
            $this->add_render_attribute('shortcode', 'amount_label', $settings['amount_label']);
        }

        $show_limit = $settings['show_limit'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'show_limit', $show_limit);

        $show_balance = $settings['show_balance'] == 'yes' ? 1 : 0;
        $this->add_render_attribute('shortcode', 'show_balance', $show_balance);

        $shortcode = do_shortcode('[mycred_transfer ' . $this->get_render_attribute_string('shortcode') . ']');
        ?>
        <div class="elementor-shortcode"><?php echo $shortcode; ?></div>

        <?php
    }

}
