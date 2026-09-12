package com.example.demo.config;

import com.example.demo.security.AutoLoginFilter;
import com.example.demo.security.CustomAuthenticationProvider;
import com.example.demo.security.CustomLoginFailureHandler;
import com.example.demo.security.CustomLoginSuccessHandler;
import com.example.demo.security.JwtTokenProvider;
import com.example.demo.security.RefreshTokenRedisService;
import jakarta.servlet.http.Cookie;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.session.HttpSessionEventPublisher;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final CustomLoginSuccessHandler customLoginSuccessHandler;
    private final CustomLoginFailureHandler customLoginFailureHandler;
    private final AutoLoginFilter autoLoginFilter;
    private final CustomAuthenticationProvider customAuthenticationProvider;

    // 💡 Redis 서비스 및 JWT 토큰 프로바이더 주입
    private final RefreshTokenRedisService redisService;
    private final JwtTokenProvider jwtTokenProvider;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        http
                .csrf(csrf -> csrf.disable())
                .cors(cors -> cors.disable())
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/css/**", "/js/**", "/images/**", "/uploads/**", "/error"
                        ).permitAll()
                        .requestMatchers(
                                "/member/update**", "/member/delete", "/member/mypage", "/member/settings"
                        ).authenticated()
                        .requestMatchers(
                                "/", "/api/**",
                                "/auth/**", "/member/**"
                        ).permitAll()
                        .requestMatchers(
                                "/index"
                        ).authenticated()
                        .anyRequest().permitAll()
                )
                .formLogin(form -> form
                        .loginPage("/auth/login")
                        .loginProcessingUrl("/auth/login")
                        .usernameParameter("memberId")
                        .passwordParameter("memberPassword")
                        .successHandler(customLoginSuccessHandler)
                        .failureHandler(customLoginFailureHandler)
                        .permitAll()
                )
                .logout(logout -> logout
                        .logoutUrl("/member/logout")
                        .logoutSuccessUrl("/")
                        .invalidateHttpSession(true)
                        .clearAuthentication(true)
                        // 💡 쿠키 삭제 대상 지정
                        .deleteCookies("JSESSIONID", "refreshToken")
                        .addLogoutHandler((request, response, authentication) -> {
                            Cookie[] cookies = request.getCookies();
                            if (cookies != null) {
                                for (Cookie cookie : cookies) {
                                    // 💡 refreshToken 쿠키 확인 후 Redis 토큰 삭제
                                    if ("refreshToken".equals(cookie.getName())) {
                                        String token = cookie.getValue();

                                        if (jwtTokenProvider.validateToken(token)) {
                                            String memberId = jwtTokenProvider.getMemberId(token);
                                            // Redis에 저장된 Refresh Token 삭제
                                            redisService.deleteRefreshToken(memberId);
                                        }

                                        // 브라우저 쿠키 삭제
                                        Cookie deleteCookie = new Cookie("refreshToken", null);
                                        deleteCookie.setPath("/");
                                        deleteCookie.setMaxAge(0);
                                        response.addCookie(deleteCookie);
                                        break;
                                    }
                                }
                            }
                        })
                )
                .sessionManagement(session -> session
                        .maximumSessions(1)
                        .expiredUrl("/auth/login?expired=true")
                )
                .addFilterBefore(
                        autoLoginFilter,
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager() {
        return new ProviderManager(customAuthenticationProvider);
    }

    @Bean
    public HttpSessionEventPublisher httpSessionEventPublisher() {
        return new HttpSessionEventPublisher();
    }
}