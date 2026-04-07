package pms.filter;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class EncodingFilter implements Filter {
    private String encoding = "UTF-8";

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        String encodingParam = filterConfig.getInitParameter("encoding");
        if (encodingParam != null && !encodingParam.isEmpty()) {
            this.encoding = encodingParam;
        }
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // Set request encoding
        request.setCharacterEncoding(encoding);
        
        // Set response encoding and content type
        response.setCharacterEncoding(encoding);
        response.setContentType("text/html; charset=" + encoding);

        // Handle the lang parameter and store in session
        String lang = httpRequest.getParameter("lang");
        if (lang != null && (lang.equals("vi") || lang.equals("en"))) {
            httpRequest.getSession().setAttribute("lang", lang);
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}
