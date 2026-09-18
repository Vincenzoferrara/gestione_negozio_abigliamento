const data = window.mycredLoyaltyWidget || {};

export const getLeaderboard = async (pointType = 'mycred_default') => {
    const response = await fetch(
        `${data.rest_url}/leaderboard?type=${pointType}`,
        {
            headers: {
                'X-WP-Nonce': data.nonce
            }
        }
    );
    return response.json();
};

export const getLogs = async (pointType = 'mycred_default') => {
    const response = await fetch(
        `${data.rest_url}/logs?type=${pointType}`,
        {
            headers: {
                'X-WP-Nonce': data.nonce
            }
        }
    );
    return response.json();
};

export const getBadges = async () => {
    const response = await fetch(
        `${data.rest_url}/badges`,
        {
            headers: {
                'X-WP-Nonce': data.nonce
            }
        }
    );
    return response.json();
};

export const getRanks = async (pointType = 'mycred_default') => {
    const response = await fetch(
        `${data.rest_url}/ranks?type=${pointType}`,
        {
            headers: {
                'X-WP-Nonce': data.nonce
            }
        }
    );
    return response.json();
};
