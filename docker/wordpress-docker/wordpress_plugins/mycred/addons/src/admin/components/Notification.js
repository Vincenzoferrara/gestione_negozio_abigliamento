import React from "react";
import { Toaster, toast } from "react-hot-toast";

const MYCRED_BRAND = "#6e2dfa";

// Unified toast function using react-hot-toast's default UI
export const showToast = (message, type = "success") => {
  if (type === "error") {
    toast.error(message);
  } else {
    toast.success(message);
  }
};

// Mount a single Toaster for the app
const Notification = () => (
  <Toaster
    position="bottom-right"
    containerClassName="mycred-addons-toaster"
    toastOptions={{
      duration: 5000,
      success: {
        iconTheme: {
          primary: MYCRED_BRAND,
          secondary: "#ffffff",
        },
      },
    }}
  />
);

export default Notification;