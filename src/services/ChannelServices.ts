import axios from "axios";

function normalizeNgPhone(input: string): string {
  const raw = (input || "").trim().replace(/\s+/g, "");
  if (!raw) return "";

  const noPlus = raw.startsWith("+") ? raw.slice(1) : raw;

  if (noPlus.startsWith("0") && noPlus.length >= 11) {
    return "234" + noPlus.slice(1);
  }

  if (noPlus.startsWith("234")) return noPlus;

  return noPlus;
}

export const EmailService = {
  async send(to: string, htmlContent: string, subject: string): Promise<boolean> {
    const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
    const FROM_EMAIL = process.env.FROM_EMAIL || "noreply@yourdomain.com";

    if (!SENDGRID_API_KEY) {
      console.error("SENDGRID_API_KEY not configured");
      return false;
    }

    try {
      const response = await axios.post(
        "https://api.sendgrid.com/v3/mail/send",
        {
          personalizations: [{ to: [{ email: to }], subject }],
          from: { email: FROM_EMAIL },
          content: [{ type: "text/html", value: htmlContent }],
        },
        {
          headers: {
            Authorization: `Bearer ${SENDGRID_API_KEY}`,
            "Content-Type": "application/json",
          },
        }
      );

      return response.status === 202;
    } catch (error: any) {
      console.error(
        "SendGrid error:",
        error?.response?.status,
        error?.response?.data || error?.message
      );
      return false;
    }
  },
};

export const SmsService = {
  async send(to: string, message: string): Promise<boolean> {
    const TERMII_API_KEY = process.env.TERMII_API_KEY;
    const TERMII_SENDER_ID = process.env.TERMII_SENDER_ID || "N-Alert";

    if (!TERMII_API_KEY) {
      console.error("TERMII_API_KEY not configured");
      return false;
    }

    const normalizedTo = normalizeNgPhone(to);

    console.log("SMS to:", normalizedTo);

    if (!normalizedTo) {
      console.error("Invalid phone number");
      return false;
    }

    try {
      const response = await axios.post(
        "https://api.ng.termii.com/api/sms/send",
        {
          to: normalizedTo,
          from: TERMII_SENDER_ID,
          sms: message,
          type: "plain",
          channel: "generic",
          api_key: TERMII_API_KEY,
        },
        { headers: { "Content-Type": "application/json" } }
      );

      console.log("Termii response:", response.data);

      return !!response.data?.message_id;
    } catch (error: any) {
      console.error(
        "Termii error:",
        error?.response?.status,
        error?.response?.data || error?.message
      );
      return false;
    }
  },
};
