export const saveSectionSettings = async (section, data) => {
    const response = await fetch(
        `${mycredLoyaltyWidgetData.rest_url}mycred-loyalty-widget/v1/settings/${section}`,
        {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-WP-Nonce': mycredLoyaltyWidgetData.nonce
            },
            body: JSON.stringify({ data })
        }
    );
    return response.json();
};

export const getSectionSettings = async (section) => {
    const response = await fetch(
        `${mycredLoyaltyWidgetData.rest_url}mycred-loyalty-widget/v1/settings/${section}`,
        {
            headers: {
                'X-WP-Nonce': mycredLoyaltyWidgetData.nonce
            }
        }
    );
    return response.json();
};

export const getAllSettings = async () => {
    const response = await fetch(
        `${mycredLoyaltyWidgetData.rest_url}mycred-loyalty-widget/v1/settings`,
        {
            headers: {
                'X-WP-Nonce': mycredLoyaltyWidgetData.nonce
            }
        }
    );
    return response.json();
};
