---
layout: post
title: Multi-Factor Authentication - Part 2
date: 2014-08-12 12:43
comments: true
categories: grails spring-security
---
At the end of [part 1](https://kyleboon.org/blog/2014/05/18/two-factor-authentication/), the first step of multi-factor authentication was finished. The second authentication step will verify a token sent via text message to the user. In order to accomplish this, there needs to be a Spring Security filter and authentication provider. The filter will be triggered when the security token is submitted by the user, it will delegate to the authentication provider which will fully authenticate the user and provide the full list of roles from the ```DaoUserDetailsProvider```. 

### Implementing the 2nd Step of authentication

```groovy
class TextMessageAuthenticationFilter extends AbstractAuthenticationProcessingFilter {
    public final static String TEXT_MESSAGE_RESPONSE_KEY = 'text_message_response'

    public TextMessageAuthenticationFilter() {
        super('/j_spring_security_text_message')
    }

    @Override
    Authentication attemptAuthentication(HttpServletRequest request,
                                         HttpServletResponse response) throws AuthenticationException {
        logger.error("Attempting text message authentication")

        if (!request.post) {
            throw new AuthenticationServiceException(
                    "Authentication method not supported: $request.method")
        }

        String userName = SecurityContextHolder.context?.authentication.principal.username
        String textMessageResponse = request.getParameter(TEXT_MESSAGE_RESPONSE_KEY)

        TextMessageAuthenticationToken authentication = new TextMessageAuthenticationToken(userName, null, textMessageResponse)
        Authentication authToken = authenticationManager.authenticate(authentication)

        return authToken
    }
}

```

This security filter retrieves the username from the ```SecurityContextHolder``` and the token from the request, then builds an ```TextMessageAuthenticationToken``` and validates it. 


```groovy
class TextMessageAuthenticationProvider implements AuthenticationProvider {
    UserDetailsService userDetailsService

    /**
     * Much of this is copied directly from
     * {@link org.springframework.security.authentication.dao.AbstractUserDetailsAuthenticationProvider}
     */
    Authentication authenticate(Authentication authentication) throws AuthenticationException {
        TextMessageAuthenticationToken authToken = (TextMessageAuthenticationToken) authentication
        String username = (authToken.principal == null) ? 'NONE_PROVIDED' : authToken.name
        UserDetails user = userDetailsService.loadUserByUsername(username)

        Boolean verifiedResponse = authToken.textMessageResponse == '1234'

        if (!verifiedResponse) {
            throw new WrongTextMessageResponse("Incorrect text message response from ${username}")
        }
        return createSuccessAuthentication(user, authToken)
    }

    @Override
    protected Authentication createSuccessAuthentication(Object principal, Authentication authentication) {
        // Ensure we return the original credentials the user supplied,
        // so subsequent attempts are successful even with encoded passwords.
        // Also ensure we return the original getDetails(), so that future
        // authentication events after cache expiry contain the details
        TextMessageAuthenticationToken result = new TextMessageAuthenticationToken(
                principal,
                authentication.credentials,
                principal.authorities)

        result.details = authentication.details

        return result
    }

    boolean supports(Class<? extends Object> authentication) {
        return (TextMessageAuthenticationToken.isAssignableFrom(authentication))
    }
}
```

The authentication provider is just validating the token from the user is '1234'. After the token is validated,  a new Authentication Token with the fully populated list of roles is created and returned. 

There is additional configuration that needs to be done to wire the beans correctly and register the beans correctly in spring security and that can been on [github](https://github.com/kyleboon/two-step-authentication-example/compare/step1...step2).

Following this, the user can authenticate with a username and password and then submit a hard coded value to be fully authenticated. 

### Next Steps

A hard coded authentication token isn't very useful. The next step would be to randomly generate a token and store it with an expiration date. Then use twilio or another service to send the token to the user. Finally, verify the token is correct and entered before the expiration date.