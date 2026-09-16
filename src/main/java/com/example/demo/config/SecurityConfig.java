package com.example.demo.config;

import com.example.demo.security.*;
import jakarta.servlet.http.Cookie;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.context.NullSecurityContextRepository;
import org.springframework.security.web.savedrequest.NullRequestCache;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final CustomAuthenticationProvider customAuthenticationProvider;

    // 💡 Redis 서비스 및 JWT 토큰 프로바이더 주입
    private final RefreshTokenRedisService redisService;
    private final JwtTokenProvider jwtTokenProvider;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        http
                // 1. 기본 보안 옵션 비활성화
                .csrf(AbstractHttpConfigurer::disable)
                .cors(AbstractHttpConfigurer::disable)
                .formLogin(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)

                // 2. 세션 미사용 및 Context 저장 차단 (Stateless 완벽 적용)
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )
                .securityContext(context -> context
                        .securityContextRepository(new NullSecurityContextRepository())
                )

                // 3. [필수] 미인증 접근 시 Spring Security의 자동 세션 캐싱 차단
                .requestCache(cache -> cache
                        .requestCache(new NullRequestCache())
                )

                // 3. Request URL 권한 설정
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

                // 4. 로그아웃 설정
                .logout(logout -> logout
                        .logoutUrl("/member/logout")
                        .logoutSuccessUrl("/")
                        .clearAuthentication(true)
                        .addLogoutHandler((request, response, authentication) -> {
                            Cookie[] cookies = request.getCookies();
                            if (cookies != null) {
                                for (Cookie cookie : cookies) {
                                    if ("refreshToken".equals(cookie.getName())) {
                                        String token = cookie.getValue();

                                        if (jwtTokenProvider.validateToken(token)) {
                                            String memberId = jwtTokenProvider.getMemberId(token);
                                            redisService.deleteRefreshToken(memberId);
                                        }

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

                // 5. JWT 필터 위치 지정
                .addFilterBefore(
                        jwtAuthenticationFilter,
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager() {
        return new ProviderManager(customAuthenticationProvider);
    }
}