package com.example.demo.config;

import com.example.demo.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        http
                .csrf(csrf -> csrf.disable())
                // React 연동 전이라 임시로 꺼둔 상태. 나중에 React를 다시 붙이면
                // cors.disable() 대신 허용 origin을 지정한 CorsConfigurationSource를 등록해야 함.
                .cors(cors -> cors.disable())
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )
                .authorizeHttpRequests(auth -> auth
                        // 정적 리소스
                        .requestMatchers(
                                "/css/**", "/js/**", "/images/**", "/uploads/**", "/error"
                        ).permitAll()

                        // 로그인/찾기/복구 등 '인증 전' 상태에서 반드시 열려있어야 하는 auth API만 명시적으로 허용
                        // (예전 /api/** 전체 permitAll 이었던 걸 /api/auth/** 로 좁힘)
                        .requestMatchers(
                                "/api/auth/**", "/auth/**"
                        ).permitAll()

                        // 회원가입/아이디·비밀번호 찾기 등 비로그인 사용자도 접근해야 하는 member 페이지
                        // (실제 경로는 프로젝트에 맞게 조정 필요 — 우선 join/find 계열만 열어둠)
                        .requestMatchers(
                                "/member/join/**", "/member/find-id", "/member/find-password"
                        ).permitAll()

                        // 로그인한 사용자만 접근 가능한 member 기능
                        .requestMatchers(
                                "/member/update**", "/member/delete", "/member/mypage", "/member/settings"
                        ).authenticated()

                        // 랜딩 페이지
                        .requestMatchers("/").permitAll()

                        // 그 외 나머지는 전부 기본적으로 인증 필요 (fail-closed)
                        // 기존 anyRequest().permitAll() 이었던 걸 authenticated() 로 변경.
                        // -> 새 API를 추가할 때 깜빡하고 화이트리스트에 안 넣어도 자동으로 막히게끔.
                        .anyRequest().authenticated()
                )
                .addFilterBefore(
                        jwtAuthenticationFilter,
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }
}