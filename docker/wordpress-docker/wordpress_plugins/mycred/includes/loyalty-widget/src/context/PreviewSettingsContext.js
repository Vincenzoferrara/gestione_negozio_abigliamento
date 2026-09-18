import { createContext, useContext, useState, useCallback, useMemo } from '@wordpress/element';
import { __ } from '@wordpress/i18n';

const PreviewSettingsContext = createContext(null);

const getInitialSettings = () => {
    const data = window.mycredLoyaltyWidgetData?.settings || {};
    const design = {
        showLogo: false,
        backgroundColor: '#000000',
        textColor: '#FFFFFF',
        buttonColor: '#000000',
        buttonTextColor: '#FFFFFF',
        showBranding: true,
        logoUrl: '',
        logoText: __('Reward Program', 'mycred'),
        launcherRadius: 45,
        launcherAnimation: 'fade',
        layoutTemplate: 'luxury',
        headerStyle: 'solid',
        headerImageUrl: window.mycredLoyaltyWidgetData?.assets_url ? window.mycredLoyaltyWidgetData.assets_url + 'mycred_widget_header.png' : '',
        headerOverlayOpacity: 0,
        headerSubtitle: __('Welcome to', 'mycred'),
        programTitle: __('Rewards Hub', 'mycred'),
        borderRadius: 8,
        showReferralOnHome: true,
        navLayout: 'grid',
        heroImageUrl: window.mycredLoyaltyWidgetData?.assets_url ? window.mycredLoyaltyWidgetData.assets_url + 'default-logo1.svg' : '',
        ...(data.design || {}),
    };
    const tpl = design.layoutTemplate === 'modern' ? 'modern' : 'luxury';
    design.layoutTemplate = tpl;
    return {
        design,
        content: data.content || {},
        tabs: data.tabs || {},
        general: data.general || {},
        eventtriggers: data.eventtriggers || {},
        faq: {
            screenTitle: 'FAQs',
            items: [],
            ...(data.faq || {}),
        },
    };
};

export function PreviewSettingsProvider({ children }) {
    const [settings, setSettings] = useState(getInitialSettings);

    const updateDesign = useCallback((patch) => {
        setSettings((prev) => ({
            ...prev,
            design: typeof patch === 'function' ? patch(prev.design) : { ...prev.design, ...patch },
        }));
    }, []);

    const setDesign = useCallback((design) => {
        setSettings((prev) => ({ ...prev, design }));
    }, []);

    const updateContent = useCallback((audience, patch) => {
        setSettings((prev) => ({
            ...prev,
            content: {
                ...prev.content,
                [audience]: typeof patch === 'function'
                    ? patch(prev.content?.[audience] || {})
                    : { ...prev.content?.[audience], ...patch },
            },
        }));
    }, []);

    const setContentAudience = useCallback((audience, data) => {
        setSettings((prev) => ({
            ...prev,
            content: { ...prev.content, [audience]: data },
        }));
    }, []);

    const updateFaq = useCallback((patch) => {
        setSettings((prev) => ({
            ...prev,
            faq: typeof patch === 'function' ? patch(prev.faq) : { ...prev.faq, ...patch },
        }));
    }, []);

    const setFaq = useCallback((faq) => {
        setSettings((prev) => ({ ...prev, faq }));
    }, []);

    const syncFromSaved = useCallback((section, data) => {
        setSettings((prev) => ({ ...prev, [section]: data }));
    }, []);

    const value = useMemo(() => ({
        settings,
        design: settings.design,
        content: settings.content,
        tabs: settings.tabs,
        general: settings.general,
        eventtriggers: settings.eventtriggers,
        faq: settings.faq,
        updateDesign,
        setDesign,
        updateContent,
        setContentAudience,
        updateFaq,
        setFaq,
        syncFromSaved,
    }), [settings, updateDesign, setDesign, updateContent, setContentAudience, updateFaq, setFaq, syncFromSaved]);

    return (
        <PreviewSettingsContext.Provider value={value}>
            {children}
        </PreviewSettingsContext.Provider>
    );
}

export function usePreviewSettings() {
    const ctx = useContext(PreviewSettingsContext);
    if (!ctx) {
        throw new Error('usePreviewSettings must be used within PreviewSettingsProvider');
    }
    return ctx;
}

export default PreviewSettingsContext;
