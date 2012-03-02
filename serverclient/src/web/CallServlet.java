package web;

import java.io.IOException;

import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import serverclient.CallingBeanRemote;

@WebServlet(urlPatterns = "/ccall")
public class CallServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

	@EJB
	CallingBeanRemote callingBean;
	
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
    	callingBean.call();
        resp.getWriter().write("Success");
    }

}
