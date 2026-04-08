package pms.filter;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.utils.PaymentService;

public class PaymentStatusFilter implements Filter {

    private FilterConfig filterConfig;
    private PaymentService paymentService;

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        this.filterConfig = filterConfig;
        this.paymentService = new PaymentService();
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String action = httpRequest.getParameter("action");

        if ("checkPayment".equals(action)) {
            String paymentIdStr = httpRequest.getParameter("payment_id");
            if (paymentIdStr != null) {
                try {
                    int paymentId = Integer.parseInt(paymentIdStr);
                    java.util.Map<String, Object> status = paymentService.getPaymentStatus(paymentId);

                    httpResponse.setContentType("application/json;charset=UTF-8");
                    PrintWriter out = httpResponse.getWriter();

                    StringBuilder json = new StringBuilder("{");
                    json.append("\"exists\":").append(status.get("exists"));
                    if (Boolean.TRUE.equals(status.get("exists"))) {
                        json.append(",\"paymentId\":").append(status.get("paymentId"));
                        json.append(",\"billId\":").append(status.get("billId"));
                        json.append(",\"amount\":").append(status.get("amount"));
                        json.append(",\"status\":\"").append(status.get("status")).append("\"");
                        json.append(",\"remainingSeconds\":").append(status.get("remainingSeconds"));
                        if (status.get("transactionId") != null) {
                            json.append(",\"transactionId\":\"").append(status.get("transactionId")).append("\"");
                        }
                    }
                    json.append("}");

                    out.write(json.toString());
                    return;
                } catch (Exception e) {
                    httpResponse.setContentType("application/json;charset=UTF-8");
                    httpResponse.getWriter().write("{\"error\":\"" + e.getMessage() + "\"}");
                    return;
                }
            }
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        this.filterConfig = null;
        this.paymentService = null;
    }
}
